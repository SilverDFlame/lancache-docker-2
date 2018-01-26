# Lancache Docker 2
An easy to use lancache made in Docker!

This project is an amalgamation between [Bntjah's Lanchache](https://github.com/bntjah/lancache) and [RyanEwan's lancache-docker](https://github.com/RyanEwen/lan-cache-docker).

The idea behind this project was to supply an easy to use deployment of a Lancache, that, since it runs inside of Docker containers, is environment agnostic and should "just work".

## What is a Lancache?
Good question! A Lancache is a server that will keep a copy/clone of files downloaded from a game's CDN server and store a copy of it for future use. This includes patches and DLC files. Once a file is requested again, whether by the original system, or a new one on the network, it will check if a copy exists, and if it does, serve it up from the cache, versus downloading again from the network.

## What gets cached?
    * Steam
    * RIOT
    * Blizard
    * Hirez
    * Origin
    * Sony
    * Microsoft
    * Tera
    * GOG
    * ArenaNetworks
    * WarGaming
    * Uplay
    * Plus a couple others!
## Other features
This lancache also spins up an instance of Unbound DNS Resolver. Unbound will cache requests from the network, and resolve them versus having to use an outside DNS resolver. This will eventually allow faster DNS queries on the network.

# How do I use this?
Clone down this repo onto a _*CLEAN*_ install of a server of your choice! _This was tested on Ubuntu 17.04 LTS._

Run the following:
```
chmod +x initialize-lancache.sh
./initialize-lancache.sh
```