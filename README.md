# Gophers (Four Different Ones)
This is a collection of very small, minimally functional [Gopher](https://en.wikipedia.org/wiki/Gopher_%28protocol%29) servers written in several different programming languages.

## A _What_ Server?
Before the World Wide Web as we know it today, we had Gopher. When I went to college in the early 1990s, the computer labs that had high-end Unix workstations running X/Windows could run the earliest versions of [NCSA Mosaic](https://en.wikipedia.org/wiki/Mosaic_(web_browser)), an early precursor to what would become Netscape Navigator. But in the dorms, we were limited to using text-based terminals, where we were able to dial-in over 2400bps modems. SLIP and PPP weren't even a thing yet. 

In those days, most "content" you could find was either text-based, or some shareware-type apps you could download. The first time I was exposed to this world was when I saw the guy living across the hall from me downloading bong-making instructions. These sort of things were usually fetched either over anonymous FTP, or if you were feeling fancy, Gopher.

Unlike the web and its hypertext, Gopher's very basic protocol is effectively menu-driven. Early web browsers included support for Gopher; in the URL bar, you could enter a URL that started with gopher:// instead of http:// and browse Gopher sites.

Gopher's popularity waned as the Web gained favor, and today a tiny cadre of defunct-technology enthusiasts maintain a few dozen Gopher servers for yucks.

## Um... why?
I like programming languages. I don't have a desire to become an expert in many of them, but I like to play around with different things to get a feel for the syntax and "ergonomics" of how the language guides you to a solution. There are [websites on the internet that document how to write "Hello World" in hundreds of programming languages](http://helloworldcollection.de/), but Hello World isn't very meaty. Gopher Servers are simple enough that you can write one in a few hours, and get an appreciation for the aesthetics of the language they're written in. Plus I have a weird obsession with Gopher, so it felt like a perfect fit.

A simple socket server probably isn't the best way to exercise some of these languages, but again, I'm interested in this hard-to-define notion of language aesthetics - I'm not trying to be a power user of any of these.

## Goals
I don't have hard and fast rules for this, but I'm trying to stick to the following:

* For each implementation, I am using as few extra libraries as possible (hopefully zero). I want to use the "standard libraries" as much as possible because I'm curious about the language, not the packaging ecosystem. 
* I'm not implementing [RFC 1436](https://tools.ietf.org/html/rfc1436) (Gopher's spec) to the letter. I'm pragmatically choosing a decent subset of Gopher functionality. I'm not trying to implement Gopher+ and certainly not trying to implement the somewhat Gopher-inspired [Gemini](https://en.wikipedia.org/wiki/Gemini_(protocol)) protocol (although I might try that next!).
* These implementations will not support any dynamically generated content.
* These toy servers won't make any effort to wrap lines that are longer than 72 columns, unlike many other "real" servers.
* I've written a tiny set of "tests" as a shell script to validate each implementation. I am using the very well-written, full featured [Gophernicus](https://www.gophernicus.org/) server (written in C) as my "reference" implementation. The basic idea is that I run the tests against Gophernicus to get an expected output, then run the same tests against my implementations to ensure they generate (approximately) the same output.
* Each implementation should support both [Gophermaps](https://en.wikipedia.org/wiki/Gopher_%28protocol%29#Source_code_of_a_menu) and dynamically generating a menu based on directory contents.
* I'm going to try to make a README in each implementation that contains rambling bloviation about stuff that I've learned and instructions on how to run it.
* I'm sure that the code for many of these is not very good. I'm not an expert in most of these languages and I'm just trying to get something to work, I'm not writing my opus. Be gentle and try not to laugh if the code looks awful.

The gopher_root directory is a sample directory from which the tests serve content. 

That's it I guess, enjoy!