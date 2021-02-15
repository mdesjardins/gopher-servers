# Python Gopher Server
This is an implementation of a basic Gopher server in the [Python programming language](https://www.python.org/).

## Running it
This server was created and tested using Python 3.8.5. There's a dataclass in it, so you'll need at least version 3.7.
    
    python gopher_server.py 
    
Optional command lines arguments are:

* --port (default is 70)
* --host (tries to get the host name by default)
* --root (root directory to serve, default is /var/gopher)

Example of passing command line args:

    python gopher_server.py --port=7070 --root=../../gopher_root
    
The server does _not_ currently run as a daemon.

## Notes on the Python implementation
This was the third server implementation I worked on. I've been using Python a lot at work lately so it was pretty quick to do - probably around 90 minutes or so? It's pretty close to a line-by-line port of the original Ruby implementation, except I used fewer classes, so it's not particularly "Pythonic" in any way (I actually like the fewer classes, I may go back and tweak the Ruby and Crystal implementations). 

I went for the threaded TCP server just because why not.
	