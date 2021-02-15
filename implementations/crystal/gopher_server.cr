require "socket"
require "log"

FILE_TYPE_MAP = {
  "0" => :txt,
  "1" => :directory,
  "2" => :nameserver,
  "3" => :error,
  "4" => :hqx,
  "5" => :archive,
  "7" => :search,
  "9" => :binary,
  "+" => :mirror,
  "g" => :gif,
  "I" => :image,
  # unofficial
  "d" => :doc,
  "h" => :html,
  "i" => :info,
  "s" => :sound,
  ";" => :video,
  "c" => :calendar,
  "M" => :mime
}

# Stolen from gophernicus.h FILETYPES. I can"t imagine this
# server will ever serve most of these. :P
FILE_EXTENSION_MAP = {
  "txt" => :txt,
  "md" => :txt,
  "pl" => :txt,
  "py" => :txt,
  "sh" => :txt,
  "tcl" => :txt,
  "c" => :txt,
  "cpp" => :txt,
  "h" => :txt,
  "log" => :txt,
  "conf" => :txt,
  "php" => :txt,
  "php3" => :txt,
  "hqx" => :hqx,
  "zip" => :archive,
  "gz" => :archive,
  "Z" => :archive,
  "tgz" => :archive,
  "bz2" => :archive,
  "rar" => :archive,
  "ics" => :calendar,
  "ical" => :calendar,
  "gif" => :gif,
  "jpg" => :image,
  "jpeg" => :image,
  "png" => :image,
  "bmp" => :image,
  "mp3" => :sound,
  "wav" => :sound,
  "flac" => :sound,
  "ogg" => :sound,
  "avi" => :video,
  "mp4" => :video,
  "mpg" => :video,
  "mov" => :video,
  "qt" => :video,
  "pdf" => :document,
  "ps" => :document,
  "doc" => :document,
  "docx" => :document,
  "ppt" => :document,
  "pptx" => :document,
  "xls" => :document,
  "xlsx" => :document,
}

MAX_MAP_FILE_SIZE = 1_000_000

# Config object
#
class Config
  class_property root : String = "/var/gopher"
  class_property mapfilename : String = "Gophermap"
  class_property port : Int32 = 70
  class_property host : String = System.hostname
end


# Represents a menu item line emitted from the gopher server
#
module MenuItem
  @type_and_name : String = ""
  @type : Symbol?
  @name : String = ""
  @file : String = ""
  @host : String = Config.host
  @port : Int32 = Config.port

  def renderable?
    ![:comment, nil].includes?(@type)
  end

  def host
    @host || Config.host
  end

  def port
    @port || Config.port
  end

  def to_s
    return "#{[@type_and_name.chomp, @file, host, port].join("\t")}" if renderable?
    return ""
  end
end


# Given a file in a directory served by Gopher, represents a corresponding line in
# the output emitted for a gopher menu.
#
class PathMenuItem
  include MenuItem

  def initialize(file)
    @name = File.basename(file.path)
    @file = File.real_path(file.path)

    if File.directory?(file.path) && File.readable?(file.path) && File.executable?(file.path)
      @type = :directory
    else
      # try to infer the type from the file extension, default to binary (we don't do anything fancy
      # here w/ reading magic numbers or whatev).
      extension = file.path.split(".").last
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
    line = "i#{line}" if !line.includes?("\t")

    fields = line.split("\t")

    # Crystal doesn't support Ruby-style optional/safe destructuring
    if fields.size > 1
      @type_and_name, @file, @host, port_s = line.split('\t')
      @port = port_s.to_i
    else
      @type_and_name = fields[0]
    end
    @type = FILE_TYPE_MAP.fetch(@type_and_name[0].to_s, nil)

    unless @type.nil?
      @name = @type_and_name[1..-1]
      return
    end

    # Invalid line. Ignore it.
    Log.warn { "Invalid line in Gophermap: #{line}" }
    @type = nil
  end
end


# Given a selector, renders a "not found" message.
#
class ErrorMenuItem
  include MenuItem

  def initialize(selector)
    @type = :error
    @name = "'#{selector}' doesn't exist!"
    @type_and_name = [FILE_TYPE_MAP.invert[@type], @name].join(" ")
  end
end

# Given a directory, reads the gophermap file and parses it into a string representation
# that can be returned to the client and rendered as a menu.
#
class GopherMenu
  @text : String

  def initialize(selector)
    @entries = [] of MenuItem
    @text = ""
    map_path = File.join(Config.root, selector, Config.mapfilename)
    if File.exists?(map_path) && File.readable?(map_path)
      build_from_gophermap(map_path)
    else
      build_from_directory_listing(selector)
    end
  end

  def build_from_gophermap(map_path)
    @text = File.read(map_path)
    @text = @text.gsub(/\r\n?/, "\n")
    @text.each_line do |line|
      @entries << GopherMapMenuItem.new(line) unless line.starts_with?('#')
    end
  end

  def build_from_directory_listing(selector)
    directory = File.join(Config.root, selector)
    filenames = Dir.glob(File.join(directory, "*"))
    files = filenames.map { |readable| File.new(readable) }
    files.select { |f| File.readable?(f.path) }.each do |file|
      @entries << PathMenuItem.new(file)
    end
  end

  def to_s
    @entries.compact_map { |line| "#{line.to_s.chomp}\r\n" unless line.to_s.nil? }.join
  end
end


# The main server class. Instantiate and call serve! Will sit on a loop
# accepting requests until killed.
#
class GopherServer
  def initialize(args={} of String => String?)
    @args = args
    Config.root = args.fetch("root", "/var/gopher").not_nil!
    Config.mapfilename = args.fetch("map", "gophermap").not_nil!
    Config.port = args.fetch("port", "70").not_nil!.to_i
    Config.host = args.fetch("host", System.hostname).not_nil!
  end

  def serve_file(client, selector)
    filename = selector_to_path(selector)
    serve_text_file(client, filename) && return if text_file?(filename)
    # Serving a binary file...
    File.open(filename, "rb") { |file| IO.copy(file, client) }
  end

  def serve_text_file(socket, filename)
    File.open(filename, "rb") do |file|
      file.each_line do |line|
        # Gotta get the line-endings just right per RFC 1436!
        socket.print "#{line.chomp}\r\n"
      end
    end
  end

  def serve_not_found_error(client, selector)
    err = ErrorMenuItem.new(selector)
    client.print "#{err.to_s.chomp}\r\n"
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
    File.join(Config.root, selector)
  end

  def text_file?(filename)
    extension = filename.split(".").last
    FILE_EXTENSION_MAP.fetch(extension, :binary) == :txt
  end

  def process(client)
    selector = client.read_line(chomp=true)
    Log.info { "Request is for #{selector.nil? ? "/" : selector}" }
    if servable_directory?(selector)
      client.puts GopherMenu.new(selector).to_s
      client.print ".\r\n"
    elsif servable_file?(selector)
      serve_file(client, selector)
    else
      serve_not_found_error(client, selector)
    end
    client.close
  end

  def serve!
    Log.info { "Starting Gopher Server at #{Config.host} on port #{Config.port}, serving from #{Config.root}" }
    server = TCPServer.new Config.port
    while client = server.accept?
      spawn process(client)
    end
  end
end

args = {} of String => String?
ARGV.join(" ").scan(/--?([^=\s]+)(?:=(\S+))?/).each do |match|
  args[match.captures[0].not_nil!] = match.captures[1]
end

begin
  GopherServer.new(args).serve!
rescue e
  Log.error { "Error starting Gopher server: #{e.message}" }
  Log.error { e.backtrace }
  exit(-1)
end
