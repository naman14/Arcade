local sundown = require 'sundown.env'
local C = sundown.C
local ffi = require 'ffi'

require 'sundown.sdcdefs'

local c = {
   none = '\27[0m',
   black = '\27[0;30m',
   red = '\27[0;31m',
   green = '\27[0;32m',
   yellow = '\27[0;33m',
   blue = '\27[0;34m',
   magenta = '\27[0;35m',
   cyan = '\27[0;36m',
   white = '\27[0;37m',
   Black = '\27[1;30m',
   Red = '\27[1;31m',
   Green = '\27[1;32m',
   Yellow = '\27[1;33m',
   Blue = '\27[1;34m',
   Magenta = '\27[1;35m',
   Cyan = '\27[1;36m',
   White = '\27[1;37m',
   _black = '\27[40m',
   _red = '\27[41m',
   _green = '\27[42m',
   _yellow = '\27[43m',
   _blue = '\27[44m',
   _magenta = '\27[45m',
   _cyan = '\27[46m',
   _white = '\27[47m'
}

local color_style = {
   maxlsz = 80,
   none = c.none,
   h1 = c.Magenta,
   h2 = c.Red,
   h3 = c.Blue,
   h4 = c.Cyan,
   h5 = c.Green,
   h6 = c.Yellow,
   blockquote = '',
   hrule = c.Black,
   link = c.green,
   linkcontent = c.Green,
   code = c.cyan,
   emph = c.Black,
   doubleemph = c.Red,
   tripleemph = c.Magenta,
   strikethrough = c._white,
   header = c.White,
   footer = c.White,
   image = c.yellow,
   ulist = c.magenta,
   olist = c.magenta,
   tableheader = c.magenta,
   superscript = '^'
}

local bw_style = {
   maxlsz = 80,
   none = '',
   h1 = '',
   h2 = '',
   h3 = '',
   h4 = '',
   h5 = '',
   h6 = '',
   blockquote = '',
   hrule = '',
   link = '',
   linkcontent = '',
   code = '',
   emph = '',
   doubleemph = '',
   tripleemph = '',
   strikethrough = '',
   header = '',
   footer = '',
   image = '',
   ulist = '',
   olist = '',
   tableheader = '',
   superscript = '^'
}

local default_style = color_style

local function textsize(text)
   local szt = 0
   local nw = 0
   for word in text:gmatch('%S+') do
      local szw = #word
      word:gsub('\027%[[%d;]+m',
                function(stuff)
                   szw = szw - #stuff
                end)
      szt = szt + szw
      nw = nw+1
   end
   if nw > 0 then
      szt = szt + nw-1
   end
   return szt
end

local function createcallbacks(style)
   local tree = {}
   local n = 0

   local callbacks = {
      blockcode =
         function(ob, text, lang, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               text = style.code .. text .. style.none
               n = n+1
               tree[n] = {tag='blockcode', text=text}
               C.sd_bufputs(ob, '\030' .. n .. '\031')
            end
         end,

      header =
         function(ob, text, level, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               level = math.max(math.min(level, 6), 1)
               text = style['h' .. level] .. text .. style.none
               n = n+1
               tree[n] = {tag='header', text=text, level=level}
               C.sd_bufputs(ob, '\030' .. n .. '\031')
            end
         end,

      blockquote =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               text = style.blockquote .. text .. style.none
               n = n+1
               tree[n] = {tag='blockquote', text=text}
               C.sd_bufputs(ob, '\030' .. n .. '\031')
            end
         end,

      blockhtml =
         function(ob, text, opaque)
            -- do nothing
         end,

      hrule =
         function(ob, opaque)
            n = n+1
            tree[n] = {tag='hrule'}
            C.sd_bufputs(ob, '\030' .. n .. '\031')
         end,

      paragraph =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               n = n+1
               tree[n] = {tag='paragraph', text=text}
               C.sd_bufputs(ob, '\030' .. n .. '\031')
            end
         end,

      table =
         function(ob, header, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
            else
               text = nil
            end

            if header ~= nil and header.data ~= nil then
               header = ffi.string(header.data, header.size)
            else
               header = nil
            end

            if text or header then
               n = n+1
               tree[n] = {tag='tbl', text=text, header=header}
               C.sd_bufputs(ob, '\030' .. n .. '\031')
            end
         end,

      table_row =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               n = n+1
               tree[n] = {tag='tblrow', text=text}
               C.sd_bufputs(ob, '\030' .. n .. '\031')
            end
         end,

      table_cell =
         function(ob, text, flags, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               if bit.band(flags, 4) > 0 then
                  text = style.tableheader .. text .. style.none
               end
               flags = bit.band(flags, 3)
               n = n+1
               tree[n] = {
                  tag='tblcell',
                  text=text,
                  size=textsize(text),
                  left=(flags==1),
                  right=(flags==2),
                  center=(flags==3)
               }
               C.sd_bufputs(ob, '\030' .. n .. '\031')
            end
         end,

      list =
         function(ob, text, flags, opaque)
            if text and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               n = n+1
               tree[n] = {tag='list', text=text, type=bit.band(flags, 1)}
               C.sd_bufputs(ob, '\030' .. n .. '\031')
            end
         end,

      listitem =
         function(ob, text, flags, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               n = n+1
               tree[n] = {tag='listitem', text=text}
               C.sd_bufputs(ob, '\030' .. n .. '\031')
            end
         end,

      normal_text =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               text = text:gsub('[\029\030\031]', '')
               C.sd_bufputs(ob, text)
            end
         end,

      entity =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               text = text:gsub('[\029\030\031]', '')
               C.sd_bufputs(ob, text)
            end
         end,

      autolink =
         function(ob, link, ltype, opaque)
            if link ~= nil and link.data ~= nil then
               link = ffi.string(link.data, link.size)
               link = style.link .. link .. style.none
               C.sd_bufputs(ob, link)
            end
            return 1
         end,

      codespan =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = ffi.string(text.data, text.size)
               text = style.code .. text .. style.none
               C.sd_bufputs(ob, text)
            end
            return 1
         end,

      double_emphasis =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = style.doubleemph .. ffi.string(text.data, text.size) .. style.none
               C.sd_bufputs(ob, text)
            end
            return 1
         end,

      emphasis =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = style.emph .. ffi.string(text.data, text.size) .. style.none
               C.sd_bufputs(ob, text)
            end
            return 1
         end,

      image =
         function(ob, link, title, alt, opaque)
            local text = style.image .. '[image: '
            if title ~= nil and title.data ~= nil then
               text = text .. ffi.string(title.data, title.size)
            elseif alt ~= nil and alt.data ~= nil then
               text = text .. ffi.string(alt.data, alt.size)
            elseif link ~= nil and link.data ~= nil then
               text = text .. ffi.string(link.data, link.size)
            end
            text = text .. ']' .. style.none
            C.sd_bufputs(ob, text)
            return 1
         end,

      linebreak =
         function(ob, opaque)
            local text = '\029'
            C.sd_bufputs(ob, text)
         end,

      link =
         function(ob, link, title, content, opaque)
            local text = ''
            if content ~= nil and content.data ~= nil then
               text = style.linkcontent .. ffi.string(content.data, content.size) .. style.none
            end
            if link ~= nil and link.data ~= nil then
               local link = ffi.string(link.data, link.size)
               if not link:match('^#') then
                  text = text .. ' ' .. style.link .. '[' .. link .. ']' .. style.none
               end
            end
            if #text > 0 then
               C.sd_bufputs(ob, text)
            end
            return 1
         end,

      raw_html_tag =
         function(ob, tag, opaque)
            -- just ignore it
            return 1
         end,

      triple_emphasis =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = style.tripleemph .. ffi.string(text.data, text.size) .. style.none
               C.sd_bufputs(ob, text)
            end
            return 1
         end,

      strikethrough =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = style.strikethrough .. ffi.string(text.data, text.size) .. style.none
               C.sd_bufputs(ob, text)
            end
            return 1
         end,

      superscript =
         function(ob, text, opaque)
            if text ~= nil and text.data ~= nil then
               text = style.superscript .. ffi.string(text.data, text.size) .. style.none
               C.sd_bufputs(ob, text)
            end
            return 1
         end,

      doc_header =
         function(ob, opaque)
         end,

      doc_footer =
         function(ob, opaque)
         end
   }

   return callbacks, tree
end


local function preprocess(txt, style)
   local callbacks, tree = createcallbacks(style)
   local c_callbacks = ffi.new('struct sd_callbacks', callbacks)
   local options = nil
   local markdown = C.sd_markdown_new(0xfff, 16, c_callbacks, options)

   local outbuf = C.sd_bufnew(64)

   C.sd_markdown_render(outbuf, ffi.cast('const char*', txt), #txt, markdown)
   C.sd_markdown_free(markdown)

   for name,_ in pairs(callbacks) do
      c_callbacks[name]:free()
   end

   txt = ffi.string(outbuf.data, outbuf.size)
   C.sd_bufrelease(outbuf)

   return txt, tree
end

local function showindent(out, text, indent)
   for line, brk in text:gmatch('([^\n]+)([\n]*)') do
      table.insert(out, string.rep(' ', indent) .. line)
      for i=1,#brk-1 do
         table.insert(out, '')
      end
   end
end

local function showjustified(out, text, indent, maxlsz)
   local lines = {}
   local szl = 0
   local line = {}

   local function newline()
      if #line > 0 then
         table.insert(lines, string.rep(' ', indent) .. table.concat(line, ' '))
         line = {}
         szl = 0
      end
   end

   for word in text:gmatch('%S+') do
      local szw = #word
      word:gsub('\027%[[%d;]+m',
                function(stuff)
                   szw = szw - #stuff
                end)

      if szl+szw+1 > maxlsz-indent then
         newline()
      end
      table.insert(line, word)
      szl = szl + szw+1
   end
   newline()

   table.insert(out, table.concat(lines, '\n'))
end

local function show(out, txt, tree, indent, style, maxlsz)
   maxlsz = maxlsz or style.maxlsz

   local idx = 1
   local node

   while true do
      local i, j
      i, j = txt:find('[^\029\030\031]+', idx)
      if i and i == idx then
         showjustified(out, txt:sub(i, j), indent, maxlsz)
         idx = j+1
      else
         i, j = txt:find('\029', idx)
         if i and i == idx then
            table.insert(out, '')
            idx = j+1
         else
            i, j = txt:find('(%b\030\031)', idx)
            if i and i == idx then
               idx = j+1
               local node = tree[ tonumber(txt:sub(i+1, j-1)) ]
               if node.tag == 'blockcode' then
                  table.insert(out, '')
                  showindent(out, node.text, indent)
               elseif node.tag == 'blockquote' then
                  table.insert(out, '')
                  show(out, node.text, tree, indent+5, style, maxlsz-5)
               elseif node.tag == 'header' then
                  table.insert(out, '')
                  indent = node.level
                  showindent(out, style['h' .. node.level] .. string.rep('+', maxlsz-indent+1) .. style.none, indent-1)
                  showjustified(out, node.text, indent-1, maxlsz)
               elseif node.tag == 'hrule' then
                  table.insert(out, '')
                  showindent(out, style.hrule .. string.rep('_', maxlsz-indent) .. style.none, indent)
               elseif node.tag == 'paragraph' then
                  table.insert(out, '')
                  showjustified(out, node.text, indent, maxlsz, style)
               elseif node.tag == 'list' then
                  if node.type == 0 then
                     for nidx in node.text:gmatch('(%b\030\031)') do
                        local subnode = tree[ tonumber(nidx:sub(2, -2)) ]
                        while subnode.text:match('^(%b\030\031)') do
                           subnode = tree[ tonumber( subnode.text:match('^(%b\030\031)'):sub(2, -2) ) ]
                        end
                        subnode.text = style.ulist .. '* ' .. style.none .. subnode.text
                     end
                  else
                     local oidx = 0
                     for nidx in node.text:gmatch('(%b\030\031)') do
                        local subnode = tree[ tonumber(nidx:sub(2, -2)) ]
                        while subnode.text:match('^(%b\030\031)') do
                           subnode = tree[ tonumber( subnode.text:match('^(%b\030\031)'):sub(2, -2) ) ]
                        end
                        oidx = oidx + 1
                        subnode.text = style.olist .. oidx .. '. ' .. style.none .. subnode.text
                     end
                  end
                  table.insert(out, '')
                  show(out, node.text, tree, indent+3, style, maxlsz)
                  table.insert(out, '')
               elseif node.tag == 'listitem' then
                  show(out, node.text, tree, indent, style, maxlsz)
               elseif node.tag == 'tbl' then
                  -- find cell sizes
                  local function rendertblsz(text, maxsz)
                     local idxrow = 0
                     for row in text:gmatch('(%b\030\031)') do
                        idxrow = idxrow + 1
                        local sz = {}
                        row = tree[ tonumber(row:sub(2, -2)) ]
                        assert(row.tag == 'tblrow')
                        local idxcell = 0
                        for cell in row.text:gmatch('(%b\030\031)') do
                           idxcell = idxcell + 1
                           sz[idxcell] = sz[idxcell] or 0
                           maxsz[idxcell] = maxsz[idxcell] or 0
                           cell = tree[ tonumber(cell:sub(2, -2)) ]
                           assert(cell.tag == 'tblcell')
                           sz[idxcell] = sz[idxcell] + cell.size
                        end
                        for idxcell=1,#sz do
                           maxsz[idxcell] = math.max(maxsz[idxcell], sz[idxcell])
                        end
                     end
                  end

                  local maxsz = {}
                  rendertblsz(node.header, maxsz)
                  rendertblsz(node.text, maxsz)

                  -- print it
                  local function rendertbl(text, maxsz, isheader)
                     local sztot = 0
                     for i=1,#maxsz do
                        sztot = sztot + maxsz[i]
                     end
                     local idxrow = 0
                     if isheader then
                        showindent(out, ' ' .. string.rep('-', sztot+(#maxsz-1)*3+2), indent)
                     end
                     for row in text:gmatch('(%b\030\031)') do
                        idxrow = idxrow + 1
                        row = tree[ tonumber(row:sub(2, -2)) ]
                        local line = {}
                        local idxcell = 0
                        for cell in row.text:gmatch('(%b\030\031)') do
                           idxcell = idxcell + 1
                           cell = tree[ tonumber(cell:sub(2, -2)) ]
                           if cell.right then
                              table.insert(line, string.rep(' ', maxsz[idxcell]-cell.size) .. cell.text)
                           elseif cell.center then
                              local szh2 = math.floor((maxsz[idxcell]-cell.size)/2)
                              table.insert(line, string.rep(' ', szh2) .. cell.text .. string.rep(' ', maxsz[idxcell]-cell.size-szh2))
                           else
                              table.insert(line, cell.text .. string.rep(' ', maxsz[idxcell]-cell.size))
                           end
                        end
                        showindent(out, '| ' .. table.concat(line, ' | ') .. ' |', indent)
                     end
                     showindent(out, ' ' .. string.rep('-', sztot+(#maxsz-1)*3+2), indent)
                  end
                  rendertbl(node.header, maxsz, true)
                  rendertbl(node.text, maxsz)
               end
            else
               break
            end
         end
      end
   end
end

local function render(txt, style)
   local tree
   local out = {}

   style = style or default_style
   txt, tree = preprocess(txt, style)

   show(out, txt, tree, 0, style)

   return table.concat(out, '\n')
end

local function color()
   default_style = color_style
   return default_style
end

local function bw()
   default_style = bw_style
   return default_style
end

return {render=render, bw=bw, color=color}
