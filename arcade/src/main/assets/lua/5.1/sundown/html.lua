local sundown = require 'sundown.env'
local ffi = require 'ffi'
local C = sundown.C

require 'sundown.sdcdefs'
require 'sundown.htmlcdefs'

local function render(txt)
   local callbacks = ffi.new('struct sd_callbacks')
   local options = ffi.new('struct sd_html_renderopt')
   C.sd_html_renderer(callbacks, options, 0)
   local markdown = C.sd_markdown_new(0xfff, 16, callbacks, options)

   local outbuf = C.sd_bufnew(64)
   C.sd_markdown_render(outbuf, ffi.cast('const char*', txt), #txt, markdown)
   C.sd_markdown_free(markdown)
   txt = ffi.string(outbuf.data, outbuf.size)
   C.sd_bufrelease(outbuf)

   return txt
end

return {render=render}
