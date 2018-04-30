local sass     = require "resty.sass"
local styles   = require "resty.sass.styles"
local tonumber = tonumber
local pairs    = pairs
local ngx      = ngx
local print    = ngx.print
local exit     = ngx.exit
local var      = ngx.var
local notfound = ngx.HTTP_NOT_FOUND
local error    = ngx.HTTP_INTERNAL_SERVER_ERROR
local io       = io
local open     = io.open
local close    = io.close
local sub      = string.sub
local nginx    = {}

local function enabled(val)
    if val == nil then return nil end
    return val == true or (val == "1" or val == "true" or val == "on")
end

local defaults = {
    cache                  = enabled(var.sass_cache),
    precision              = tonumber(var.sass_precision)             or 5,
    output_style           = tonumber(var.sass_output_style)          or styles[var.sass_output_style] or 0,
    source_comments        = enabled(var.sass_source_comments)        or false,
    source_map             = enabled(var.sass_source_map)             or false,
    source_map_embed       = enabled(var.sass_source_map_embed)       or false,
    source_map_contents    = enabled(var.sass_source_map_contents)    or false,
    source_map_url         = var.sass_source_map_url,
    omit_source_map_url    = enabled(var.sass_omit_source_map_url)    or false,
    is_indented_syntax_src = enabled(var.sass_is_indented_syntax_src) or false,
    include_path           = var.sass_include_path,
    plugin_path            = var.sass_plugin_path
}

function nginx.compile(options)
    ngx.header.content_type = "text/css"

    local inp = var.request_filename

    local f = open(inp, "r")

    if not f then
        exit(notfound)
    end
    close(f)

    local c = options or defaults
    local s = sass.new()
    local o = s.options

    for k, v in pairs(defaults) do
        local opt = c[k] or v
        if opt then
            o[k] = opt
        end
    end

    if o.source_map then
        o.source_map_file = inf .. ".map"
    end

    local c, err = s:compile_file(inp)

    if c then
        return print(c)
    else
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR

        return print(err)
    end
end

return nginx
