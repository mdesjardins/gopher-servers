# Crystal Gopher Server
This is an implementation of a basic Gopher server in the [Crystal programming language](https://crystal-lang.org/).

## Running it
This server was created and tested using Crystal 0.35.1. The easiest way to run it is to just do the following at the command line:
    
    crystal gopher_server.cr 
 
However, probably the coolest thing about Crystal is that you can compile native binaries. If you want to do that, first you'll need to compile the program:

    crystal build gopher_server.cr
    
Which will create a binary in your directory named **gopher_server**. With that, you can just run the executable directly.

Optional command lines arguments are:

* --port (default is 70)
* --host (tries to get the host name by default)
* --root (root directory to serve, default is /var/gopher)

Example of passing command line args:

    gopher_server --port=7070 --root=../../gopher_root
    
The server does _not_ currently run as a daemon.

## Notes on the Crystal implementation
Crystal was the second Gopher server I wrote. Because Crystal's whole schtick is basically "Ruby, but compiled and with type safety," I figured it'd be super simple to just port it over. For the most part, it was, but having never written a line of Crystal before this, a few things surprised me:

* If you've been writing Ruby for a long time, you probably just think that chars and strings are the same thing. You might even get a little sloppy and haphazardly use single and double quotes interchangeably. You can't get away with that in Crystal, and there were quite a few places where I had to clean this up.
* Dealing with nil safety was predictably irritating, but it found what were likely some bugs in the Ruby implementation. This doesn't surprise me, but it was cool to see it come to light.
* No globals. I was lazy and used globals on the ruby version for configuration values and I had to re-do that. I should've known better anyway.
* There are subtle differences in how each language handles regular expressions that caused me a little confusion (e.g., `MatchData`'s API isn't _quite_ the same), and that confusion was compounded by the fact that Crystal doesn't have a notion of "optional" destructuring. E.g., in ruby, you can do this: `var1, var2, var3 = function_that_returns_array_of_two_strings` and  `var3` will just be initialized to `nil`. In Crystal, you end up with a runtime error because the function returned an array with too few elements to destruct.

In all it was pretty painless, though. I'd say porting the Ruby server to Crystal took less than an hour! Diffing the two versions might be interesting if you're curious about how they compare (plus I might've forgotten some stuff). As a longtime Ruby fan, I'd definitely consider using Crystal on a future project.
