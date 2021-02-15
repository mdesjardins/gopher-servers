# Ruby Gopher Server
This is an implementation of a basic Gopher server in the [Ruby programming language](https://www.ruby-lang.org/).

## Running it
This server was created and tested using Ruby 2.5.1p57.  I haven't tried it with Ruby 3 yet. To run it, just do the following at the command line:
    
    ruby gopher_server.rb 
    
Optional command lines arguments are:

* --port (default is 70)
* --host (tries to get the host name by default)
* --root (root directory to serve, default is /var/gopher)

Example of passing command line args:

    ruby gopher_server.rb --port=7070 --root=../../gopher_root
    
The server does _not_ currently run as a daemon.

## Notes on the Ruby implementation
Ruby was the first language I attempted this in, so it took me a bit longer than I expect the remaining languages because I was learning the basics about Gopher's (admittedly simple) protocol. Stuff like:

* Gopher URLs, when used with most browsers and command-line tools like [curl](https://curl.se/), are prepended with the filetype as part of the path. E.g., a text file named elvis.txt in the root directory is accessed at **gopher://hostname/0/elvis.txt** (note the 0/, indicating a test file type, is prepended to the selector name in the URL)
* Getting the carriage-return + linefeeds just right is kind of a pain - everywhere you emit strings, you're best of "chomping" off any end-of-line characters and re-adding \r\n manually.
* The "i" (info) type is a little strange, especially because I was attempting to keep Gophernicus compatability. Gophernicus assumes any lines that are missing a tab character are treated as "info" lines. But what are you supposed to do if you encounter a tabless line with 'i' as the type? Are you supposed to remove the "i"? I did what Gophernicus does, and kept it.
* I kinda wanted to make this a daemon but... didn't (ran out of steam).

	