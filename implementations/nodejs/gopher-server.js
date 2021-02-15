const net = require("net")
const fs = require("fs")
const fsp = require("fs").promises  // Use both versions for funsies.
const path = require("path")
const readline = require("readline")

// defaults
let config = {
    port: 70,
    host: "localhost",
    root: "/var/gopher",
    mapfilename: "gophermap"
}

const fileType = {
    TEXT: 0,
    DIRECTORY: 1,
    NAMESERVER: 2,
    ERROR: 3,
    HQX: 4,
    ARCHIVE: 5,
    SEARCH: 7,
    BINARY: 9,
    MIRROR: 100,
    GIF: 101,
    IMAGE: 102,
    DOCUMENT: 103,
    HTML: 104,
    INFO: 105,
    SOUND: 106,
    VIDEO: 107,
    CALENDAR: 108
}

fileTypeMap = {
    '0': fileType.TEXT,
    '1': fileType.DIRECTORY,
    '2': fileType.NAMESERVER,
    '3': fileType.ERROR,
    '4': fileType.HQX,
    '5': fileType.ARCHIVE,
    '7': fileType.SEARCH,
    '9': fileType.BINARY,
    '+': fileType.MIRROR,
    'g': fileType.GIF,
    'I': fileType.IMAGE,
    'd': fileType.DOCUMENT,
    'h': fileType.HTML,
    'i': fileType.INFO,
    's': fileType.SOUND,
    ';': fileType.VIDEO,
    'c': fileType.CALENDAR
}
var inverseFileTypeMap = {}
for(var key in fileTypeMap) {
    inverseFileTypeMap[fileTypeMap[key]] = key
}

// Stolen from gophernicus.h FILETYPES.
fileExtensionMap = {
    'txt': fileType.TEXT,
    'md': fileType.TEXT,
    'pl': fileType.TEXT,
    'py': fileType.TEXT,
    'sh': fileType.TEXT,
    'tcl': fileType.TEXT,
    'c': fileType.TEXT,
    'cpp': fileType.TEXT,
    'h': fileType.TEXT,
    'log': fileType.TEXT,
    'conf': fileType.TEXT,
    'php': fileType.TEXT,
    'php3': fileType.TEXT,
    'hqx': fileType.HQX,
    'zip': fileType.ARCHIVE,
    'gz': fileType.ARCHIVE,
    'Z': fileType.ARCHIVE,
    'tgz': fileType.ARCHIVE,
    'bz2': fileType.ARCHIVE,
    'rar': fileType.ARCHIVE,
    'ics': fileType.CALENDAR,
    'ical': fileType.CALENDAR,
    'gif': fileType.GIF,
    'jpg': fileType.IMAGE,
    'jpeg': fileType.IMAGE,
    'png': fileType.IMAGE,
    'bmp': fileType.IMAGE,
    'mp3': fileType.SOUND,
    'wav': fileType.SOUND,
    'flac': fileType.SOUND,
    'ogg': fileType.SOUND,
    'avi': fileType.VIDEO,
    'mp4': fileType.VIDEO,
    'mpg': fileType.VIDEO,
    'mov': fileType.VIDEO,
    'qt': fileType.VIDEO,
    'pdf': fileType.DOCUMENT,
    'ps': fileType.DOCUMENT,
    'doc': fileType.DOCUMENT,
    'docx': fileType.DOCUMENT,
    'ppt': fileType.DOCUMENT,
    'pptx': fileType.DOCUMENT,
    'xls': fileType.DOCUMENT,
    'xlsx': fileType.DOCUMENT,
}



// Process command line args
const args = process.argv.slice(2)
for (const arg of args) {
    let [argname, value] = arg.split('=')
    console.log(`arg ${arg} switch ${argname} value ${value}`)
    switch (argname) {
        case '--root':
            config.root = value
            break
        case '--port':
            config.port = value
            break
        case '--host':
            config.host = value
            break
        case '--map':
            config.mapfilename = value
            break
        default:
            console.log(`Unrecognized command line argument: ${argname}`)
            exit(-1)
    }
}


// Utility Functions

// Node doesn't have its own "chomp" function?
const chomp = (s) => {
    if (s.length < 1) {
        return s
    }
    let result = s.slice(0, s.length)
    while (result.length > 1 &&
           (result[result.length - 1] === '\n' || result[result.length - 1] === '\r')) {
        result = result.slice(0, result.length - 1)
    }
    return result
}

// Given a selector, returns the filesystem path to it.
const selectorToFilename = (selector) => {
    return chomp(path.resolve(path.join(config.root, selector)))
}


// Builds a gopher menu from directory content, or from a gophermap.
class MenuBuilder {
    constructor(socket) {
        this.socket = socket
        this.entries = []
    }

    async buildFromGophermap(mapfile) {
        const data = await fs.promises.readFile(mapfile)
        const lines = chomp(data.toString()).split(/\r\n|\n|\r/)
        for (var line of lines) {
            if (!line.startsWith('#')) {
                if (line.indexOf("\t") < 0) {
                    line = `i${line}`
                }

                const fields = line.split('\t')
                var fileTypeAndName = fields[0]
                var filename = ""
                var host = config.host
                var port = config.port
                if (fields.length > 1) {
                    [fileTypeAndName, filename, host, port] = line.split("\t")
                }
                if (fileTypeMap[fileTypeAndName[0]] !== undefined) {
                    this.entries.push([fileTypeAndName, filename, host, port].join("\t"))
                } else {
                    console.log(`Invalid line in Gophermap: ${line}`)
                }
            }
        }
        this.entries.push(".\r\n")
    }

    async buildFromDirectoryContents(directory) {
        const files = await fs.promises.readdir(directory, { withFileTypes: true })
        for (var file of files) {
            const filename = path.join(directory, file.name)
            try {
                fs.accessSync(filename, fs.constants.R_OK)
                var type = fileType.DIRECTORY  // default
                if (file.isFile()) {
                    const extension = path.extname(filename).substring(1)
                    type = fileExtensionMap[extension]
                    if (type == undefined) {
                        type = fileType.BINARY
                    }
                }
                const fileTypeAndName = `${inverseFileTypeMap[type]}${file.name}`
                this.entries.push([fileTypeAndName, filename, config.host, config.port].join("\t"))
            } catch(e) {
                console.log(`Unable to read ${filename}`)
            }
        }
        this.entries.push(".\r\n")
    }
}


// The meat and potatoes.

// The main server is built here.
const server = net.createServer((socket) => {

    const serveNotFoundError = (socket, selector) => {
        socket.write([`3 '${selector}' doesn't exist!`, "", config.host, config.port].join("\t") + "\r\n")
        socket.end()
    }

    const serveDirectory = (socket, selector) => {
        const filename = selectorToFilename(selector)
        console.log(`Serving ${filename}`)

        const mapfile = path.join(filename, config.mapfilename)
        const menuBuilder = new MenuBuilder(socket)

        fs.access(mapfile, async (err) => {
            if (err && err.code == "ENOENT") {
                await menuBuilder.buildFromDirectoryContents(filename)
            } else {
                await menuBuilder.buildFromGophermap(mapfile)
            }

            socket.write(menuBuilder.entries.join("\r\n"), () => {
                socket.end()
            })
        })
    }

    const serveFile = (socket, selector) => {
        const filename = selectorToFilename(selector)
        console.log(`Serving ${filename}`)
        if (isTextFile(filename)) {
            serveTextFile(socket, filename)
        } else {
            fs.readFile(filename, (err, data) => {
                if (err) throw err
                socket.write(data, () => {
                    socket.end()
                })
            })
        }
    }

    const serveTextFile = (socket, filename) => {
        const rl = readline.createInterface({
            input: fs.createReadStream(filename),
            terminal: false,
            crlfDelay: Infinity
        })

        rl.on('line', (line) => {
            socket.write(`${line}\r\n`)
        })
        rl.on('close', () => {
            socket.end()
        })
    }

    const isTextFile = (selector) => {
        const extension = path.extname(selectorToFilename(selector)).substring(1)
        return fileExtensionMap[extension] == fileType.TEXT
    }

    socket.on('data', function(chunk) {
        var selector = chomp(chunk.toString())
        console.log(`Request is for ${selector}`)
        fs.stat(selectorToFilename(selector), (err, stats) => {
            if (err && err.code == 'ENOENT'){
                serveNotFoundError(socket, selector)
            } else if (err) {
                console.log(`Error stating file: ${err}`)
            } else if (stats.isFile() && (stats.mode && fs.constants.R_OK)) {
                serveFile(socket, selector)
            } else if (stats.isDirectory() && (stats.mode && fs.constants.R_OK)) {
                serveDirectory(socket, selector)
            }
        })
    });
    socket.on('end', socket.end)
});


// Will throw port errors and other errors
server.on("error", (err) => {
  throw err
})

// Lets us know that the server is up and listening
server.listen(config.port, () => {
  console.log(`Starting Gopher Server at ${config.host} on port ${config.port}, serving from ${config.root}`);
})
