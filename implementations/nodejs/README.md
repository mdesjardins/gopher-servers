# NodeJS Gopher Server
This is an implementation of a basic Gopher server using the [Javascript](https://en.wikipedia.org/wiki/JavaScript)/[ECMAScript](https://www.ecma-international.org/publications-and-standards/standards/ecma-262/) programming language, using the [Node](https://nodejs.org/en/) runtime environment.

## Running it
This server was created and tested using Node 14.4.0. It uses the fsPromises module of the standard library, so you'll need at least version 11.0.0 for this to work. Staying true to the spirit of this project, no [npm](https://www.npmjs.com/) modules were used to create this - instead I stuck with what was provided out-of-the-box with Node. So instead of running this with, e.g., npx, you just run it directly like this:
    
    node gopher-server.js
    
Optional command lines arguments are:

* --port (default is 70)
* --host (tries to get the host name by default)
* --root (root directory to serve, default is /var/gopher)

Example of passing command line args:

    node gopher-server.js --port=7070 --root=../../gopher_root
    
The server does _not_ currently run as a daemon.

## Notes on the Node implementation
This was the fourth server implementation I worked on. I used to do a lot more Javascript programming a few years ago (I was primarily a React developer at my last job), but I've forgotten some Node stuff since then. This probably took me 90-120 minutes to get fully working. I got tripped up by some of the APIs. 

Why is there no `chomp` function for cryin' out loud? I ended up rolling my own but that seems a bit ridiculous.

I seem to be falling into a pattern of doing line-by-line ports of the original Ruby implementation, and that's really not what I wanted to be doing when I embarked on this project. I'm afraid that I might be getting a little lazy.

I have a mix of callback-style API calls and async/await style calls. I only managed to fall back on a synchronous filesystem operation once (when building a menu from a directory, I needed to ensure that files are readable). I could probably make this asynchronous too with a tiny bit of effort, but (again) I guess I'm feeling a bit lazy right now.

This implementation currently does *not* pass my automated tests, only because the directory listing is in a nondeterministic order, so diffing the menu emitted from the `whitman` directory never passes. I could probably make it pass by sorting the file list, but that seems rather silly, as it'd likely degrade performance some infintesimal amount only for the sake of passing a test. I suppose I could also make the tests a little smarter.

