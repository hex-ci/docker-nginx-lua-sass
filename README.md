# Nginx with Lua module for Docker

Base on Alpine Nginx with Lua module, and support sass language.

Nginx version: 1.12.2

SASS version: 3.5.4

## Build

To build the container run: `docker build -t your-name .`

## Run

To start the container run: `docker run --name your-name -v /your/html/path:/usr/share/nginx/html -p your-port:80 -d codeigniter/nginx-lua-sass:3`

Custom Nginx configurationn: `docker run --name your-name -v /your/html/path:/usr/share/nginx/html -v /your/path/default.conf:/etc/nginx/conf.d/default.conf -p your-port:80 -d codeigniter/nginx-lua-sass:3`

## Usage

You can directly access the `.scss` and `.sass` file, and Nginx will automatically compile and output to the browser.

Support inline SASS/SCSS, example:

```scss
<style type="text/scss">
.demo-1 {
   color: red;

  .demo-1-1 {
     color: blue;
  }
}
</style>
```

```sass
<style type="text/sass">
nav
  ul
    margin: 0
    padding: 0
    list-style: none

  li
    display: inline-block

  a
    display: block
    padding: 6px 12px
    text-decoration: none
</style>
```
