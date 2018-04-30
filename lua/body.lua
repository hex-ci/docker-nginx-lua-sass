local zlib = require "zlib"
local sass = require "resty.sass"

function decode(str)
  if unexpected_condition then error() end

  local stream = zlib.inflate()
  local ret = stream(str)

  return ret
end

function callback()

  local scss_obj = sass.new()

  scss_obj.options.output_style = 1
  scss_obj.options.source_map_embed = true
  scss_obj.options.source_map_contents = true

  scss_obj.options.is_indented_syntax_src = false

  local sass_obj = sass.new()

  sass_obj.options.output_style = 1
  sass_obj.options.source_map_embed = true
  sass_obj.options.source_map_contents = true

  sass_obj.options.is_indented_syntax_src = true


  local str = ngx.arg[1]

  local str_style = string.gsub(str, '<style%s+type%s*=%s*"text/scss"%s*>([^<]+)</style>', function(text)
    local result, err = scss_obj:compile_data(text)

    if err then
      return err
    else
      return '<style type="text/css">' .. result .. '\n</style>'
    end
  end)

  str_style = string.gsub(str_style, '<style%s+type%s*=%s*"text/sass"%s*>([^<]+)</style>', function(text)
    local result, err = sass_obj:compile_data(text)

    if err then
      return err
    else
      return '<style type="text/css">' .. result .. '\n</style>'
    end
  end)

  ngx.arg[1] = str_style
end

if ngx.arg[1] ~= '' then
  if ngx.ctx.body == nil then
    ngx.ctx.body = ''
  end

  ngx.ctx.body = ngx.ctx.body .. ngx.arg[1]
end

if ngx.arg[2] then
  local body = ngx.ctx.body
  local status, debody = pcall(decode, body)

  if status then
    ngx.arg[1] = debody
  end

  callback()

  return
else
  ngx.arg[1] = nil
end
