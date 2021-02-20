# Java Gopher Server
### AT LAST, AN ENTERPRISE GRADE GOPHER SERVER.

This is an implementation of a Basic Gopher Server in the [Java programming language](https://www.oracle.com/java/technologies/). Perhaps you've heard of it.

## Running it
This server was created and tested using Java JDK 11.0.1. For the other servers I've used a basic text editor ([Emacs](https://www.gnu.org/software/emacs/)), but this time I actually cheesed out and used JetBrains's wonderful [IntellJ IDEA Community Edition](https://www.jetbrains.com/idea/) to build and run it, and I included the project files in the git repo. 

Normally, you would just create a build configuration within IDEA to run this thing (as I did), but I'm going to assume you don't want to do that, and that you want to build and run this thing on the command line. So here are the commands:

First, compile it (assuming `javac` is in your path):
   
    javac -sourcepath src -d out src/net/mikedesjardins/gopher/server/*.java

Then run it (again, assuming `java` is in your path):

    java -classpath /Users/mdesjardins/_play/gopher-servers/implementations/java/out net.mikedesjardins.gopher.server.Main
      
Optional command lines arguments are:

* --port (default is 70)
* --host (tries to get the host name by default)
* --root (root directory to serve, default is /var/gopher)

Example of passing command line args:

    java -classpath /Users/mdesjardins/_play/gopher-servers/implementations/java/out net.mikedesjardins.gopher.server.Main --port=7070 --root=../../gopher_root
    
The server does _not_ currently run as a daemon.

## Notes on the Java implementation
This is the fifth one of these things I've built. To be honest, I forgot how much fun Java can be. Java gets crapped on a lot for its verbosity, and the cumbersome design patterns you sometimes need to follow to bend it to your will. But as one of the earliest languages I've worked with, it was like an old friend ... the strictness of its object-orientedness and the verbosity is kind of charming.

I still do some occasional Android development as part of my day job, so it wasn't at all foreign to me despite the fact that most of our codebase at work is in Kotlin now.

This took me about 3 hours maybe? Longer than I thought it world! But it was one of the more enjoyable. I kinda got silly and made Factory classes and whatnot, probably way too many classes. But this was also an implementation where I went at it with more of a "clean slate," instead of falling into the same trap of just porting my other implementations to a new language.