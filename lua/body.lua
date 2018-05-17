local zlib = require "zlib"
local sass = require "resty.sass"

function decode(str)
  if unexpected_condition then error() end

  local stream = zlib.inflate()
  local ret = stream(str)

  return ret
end

function compile(str)

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

  str = ngx.re.gsub(str, [[<style\s+?type\s*?=\s*?"\s*?(.+?)\s*?"\s*?>([\s\S]+?)<\/style>]], function(match)
    local result, err

    if match[1] == 'text/scss' then
      result, err = scss_obj:compile_data(match[2])
    elseif match[2] == 'text/sass' then
      result, err = sass_obj:compile_data(match[2])
    else
      return match[0]
    end

    if err then
      return '<p>[' .. match[1] .. '] ' .. err .. '</p><script>console.error(`[' .. match[1] .. '] ' .. err .. '`)</script>'
    else
      return '<style type="text/css">\n' .. result .. '\n</style>'
    end
  end, 'ijo')

  return str
end

if ngx.re.match(ngx.header.content_type, [[^text/html]]) then

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
      debody = compile(debody)

      ngx.arg[1] = debody
    else
      body = compile(body)

      ngx.arg[1] = body
    end
  else
    ngx.arg[1] = nil
  end

end
