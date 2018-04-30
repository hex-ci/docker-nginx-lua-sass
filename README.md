# Nginx with Lua module for Docker

Base on Alpine Nginx with Lua module, and support sass language.

Nginx version: 1.12.2

SASS version: 5.5.4

## Build

To build the container run: `docker build -t your-name .`

## Usage

`docker run --name your-name -v /your/html/path:/usr/share/nginx/html -p your-port:80 -d codeigniter/nginx-lua-sass:3`
