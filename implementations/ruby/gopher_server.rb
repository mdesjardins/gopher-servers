require 'socket'

FILE_TYPE_MAP = {
  '0' => :txt,
  '1' => :directory,
  '2' => :nameserver,
  '3' => :error,
  '4' => :hqx,
  '5' => :archive,
  '7' => :search,
  '9' => :binary,
  '+' => :mirror,
  'g' => :gif,
  'I' => :image,
  # unofficial
  'd' => :doc,
  'h' => :html,
  'i' => :info,
  's' => :sound,
  ';' => :video,
  'c' => :calendar
}

# Stolen from gophernicus.h FILETYPES.
FILE_EXTENSION_MAP = {
  'txt' => :txt,
  'md' => :txt,
  'pl' => :txt,
  'py' => :txt,
  'sh' => :txt,
  'tcl' => :txt,
  'c' => :txt,
  'cpp' => :txt,
  'h' => :txt,
  'log' => :txt,
  'conf' => :txt,
  'php' => :txt,
  'php3' => :txt,
  'hqx' => :hqx,
  'zip' => :archive,
  'gz' => :archive,
  'Z' => :archive,
  'tgz' => :archive,
  'bz2' => :archive,
  'rar' => :archive,
  'ics' => :calendar,
  'ical' => :calendar,
  'gif' => :gif,
  'jpg' => :image,
  'jpeg' => :image,
  'png' => :image,
  'bmp' => :image,
  'mp3' => :sound,
  'wav' => :sound,
  'flac' => :sound,
  'ogg' => :sound,
  'avi' => :video,
  'mp4' => :video,
  'mpg' => :video,
  'mov' => :video,
  'qt' => :video,
  'pdf' => :document,
  'ps' => :document,
  'doc' => :document,
  'docx' => :document,
  'ppt' => :document,
  'pptx' => :document,
  'xls' => :document,
  'xlsx' => :document,
}


# Global config object 'cuz I'm kinda lazy.
$config = {}


# Represents a menu item line emitted from the gopher server
#
module MenuItem
  def renderable?
    ![:comment, nil].include?(@type)
  end

  def host
    @host || $config[:host]
  end

  def port
    @port || $config[:port]
  end

  def to_s
    return "#{[@type_and_name.chomp, @file, host, port].join("\t")}" if renderable?
  end
end


# Given a file in a directory served by Gopher, represents a corresponding line in
# the output emitted for a gopher menu.
#
class PathMenuItem
  include MenuItem

  def initialize(file)
    @name = File.basename(file)
    @file = File.absolute_path(file)

    if File.directory?(file) && File.readable?(file) && File.executable?(file)
      @type = :directory
    else
      # try to infer the type from the file extension, default to binary (we don't do anything fancy
      # here w/ reading magic numbers or whatev).
      extension = file.path.split('.').last
      @type = FILE_EXTENSION_MAP.fetch(extension, :binary)
    end

    @type_and_name = [FILE_TYPE_MAP.invert[@type], @name].join
  end
end


# Given an entry in a gophermap file, represents a corresponding line in the output
# emitted for a gopher menu.
#
class GopherMapMenuItem
  include MenuItem

  def initialize(line)
    # Any lines that do not contain any tabs should be converted
    # to the "info" type and rendered as such. This causes the buggy
    # behavior of rendering info lines that do not contain tabs with
    # preceding i's, but this is how Gophernicus works so if it's
    # good enough for Gophernicus...
    line = "i#{line}" if !line.include?("\t")

    @type_and_name, @file, @host, @port = line.split("\t")
    @type = @type_and_name[0]

    if FILE_TYPE_MAP.has_key?(@type)
      @name = @type_and_name[1..-1]
      return
    end

    # Invalid line. Ignore it.
    warn "Invalid line in Gophermap: #{line}"
    @type = nil
  end
end


# Given a selector, renders a "not found" message.
#
class ErrorMenuItem
  include MenuItem

  def initialize(selector)
    @type = FILE_TYPE_MAP.invert[:error]
    @name = "'#{selector}' doesn't exist!"
    @type_and_name = [@type, @name].join(' ')
  end
end


# Given a directory, reads the gophermap file and parses it into a string
# representation that can be returned to the client and rendered as a menu.
#
class GopherMenu
  def initialize(selector)
    @entries = []

    map_path = File.join($config[:root], selector, $config[:mapfilename])
    if File.exists?(map_path) && File.readable?(map_path)
      build_from_gophermap(map_path)
    else
      build_from_directory_listing(selector)
    end
  end

  def build_from_gophermap(map_path)
    @text = File.open(map_path).read
    @text.gsub!(/\r\n?/, "\n")
    @text.each_line do |line|
      @entries << GopherMapMenuItem.new(line) unless line[0] == '#'
    end
  end

  def build_from_directory_listing(selector)
    directory = File.join($config[:root], selector)
    filenames = Dir.glob(File.join(directory, '*'))
    files = filenames.map { |readable| File.new(readable) }
    files.select { |f| File.readable?(f) }.each do |file|
      @entries << PathMenuItem.new(file)
    end
  end

  def to_s
    @entries.select { |e| !e.nil? }.map { |line| "#{line.to_s.chomp}\r\n" }.join
  end
end


# The main server class. Instantiate and call serve! Will sit on a loop
# accepting requests until killed.
#
class GopherServer
  def initialize(args={})
    @args = args
    $config[:root] = args.fetch('root', '/var/gopher')
    $config[:mapfilename] = args.fetch(:map, 'gophermap')
    $config[:port] = args.fetch('port', '70').to_i
    $config[:host] = args.fetch('host', Socket.gethostname)
  end

  def serve_file(socket, selector)
    filename = selector_to_path(selector)
    serve_text_file(socket, filename) && return if text_file?(filename)
    # Serving a binary file...
    File.open(filename, 'rb') { |file| IO.copy_stream(file, socket) }
  end

  def serve_text_file(socket, filename)
    File.open(filename, 'rb') do |file|
      file.each_line do |line|
        # Gotta get the line-endings just right per RFC 1436!
        socket.print "#{line.chomp}\r\n"
      end
    end
  end

  def serve_not_found_error(socket, selector)
    err = ErrorMenuItem.new(selector)
    socket.print "#{err.to_s.chomp}\r\n"
  end

  def servable_directory?(selector)
    path = selector_to_path(selector)
    File.directory?(path) &&
      File.readable?(path) &&
      File.executable?(path)
  end

  def servable_file?(selector)
    path = selector_to_path(selector)
    File.file?(path) && File.readable?(path) #&& !File.writable?(path)
  end

  def selector_to_path(selector)
    File.join($config[:root], selector)
  end

  def text_file?(filename)
    extension = filename.split('.').last
    FILE_EXTENSION_MAP.fetch(extension, :binary) == :txt
  end

  def serve!
    warn "Starting Gopher Server at #{$config[:host]} on port #{$config[:port]}, serving from #{$config[:root]}"
    server = TCPServer.new $config[:port]
    loop do
      Thread.start(socket=server.accept) do |client|
        selector = client.gets.chomp
        warn "Request is for #{selector.empty? ? '/' : selector}"
        if servable_directory?(selector)
          client.puts GopherMenu.new(selector).to_s
          client.print ".\r\n"
        elsif servable_file?(selector)
          serve_file(socket, selector)
        else
          serve_not_found_error(socket, selector)
        end
        client.close
      end
    end
  end
end

args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]

begin
  GopherServer.new(args).serve!
rescue => e
  warn "Error starting Gopher server: #{e.message}"
  warn e.backtrace
  exit(-1)
end
