--------------------------------------------------------------------------------
-- inline help
-- that file defines all the tools and goodies to generate inline help
--------------------------------------------------------------------------------
local function splitpackagepath()
   local str = package.path
   local t = {} 
   local last_end = 1
   local s, e, cap = string.find(str, "(.-);", 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = string.find(str, "(.-);", last_end)
   end
   if last_end <= string.len(str) then
      cap = string.sub(str, last_end)
      table.insert(t, cap)
   end
   -- get package prefixes
   for i=1,#t do
      local s,p = t[i]:find('?')
      if s then t[i] = t[i]:sub(1,s-1) end
   end
   -- remove duplicates
   local t2 = {}
   for i=1,#t do
      local exists = false;
      for j=1,#t2 do if t[i] == t2[j] then 
	    exists = true end; 
      end
      if not exists then table.insert(t2, t[i]) end
   end
   return t2
end
local mdsearchpaths = splitpackagepath()

local knownpkg = {}

-- Lua 5.2 compatibility
local unpack = unpack or table.unpack
local loadstring = loadstring or load

dok.inline = {}

dok.colors = {
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
local c = dok.colors

local style = {}
function dok.usecolors()
   style = {
      banner = '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++',
      list = c.blue .. '> ' .. c.none,
      title = c.Magenta,
      pre = c.cyan,
      em = c.Black,
      bold = c.Black,
      img = c.red,
      link = c.red,
      code = c.green,
      error = c.Red,
      none = c.none
   }
end
function dok.dontusecolors()
   style = {
      banner = '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++',
      list = '> ',
      title = '',
      pre = '',
      em = '',
      bold = '',
      img = '',
      link = '',
      code = '',
      error = '',
      none = ''
   }
end
dok.usecolors()

local function uncleanText(txt)
   txt = txt:gsub('&#39;', "'")
   txt = txt:gsub('&#42;', '%*')
   txt = txt:gsub('&#43;', '%+')
   txt = txt:gsub('&lt;', '<')
   txt = txt:gsub('&gt;', '>')
   return txt
end

local function string2symbol(str)
   local str  = str:gsub(':','.')
   local ok, res = pcall(loadstring('local t = ' .. str .. '; return t'))
   if not ok then
      ok, res = pcall(loadstring('local t = _torchimport.' .. str .. '; return t'))
   end
   return res
end

local function maxcols(str, cols)
   cols = cols or 70
   local res = ''
   local k = 1
   local color = false
   for i = 1,#str do
      res = res .. str:sub(i,i)
      if str:sub(i,i) == '\27' then
         color = true
      elseif str:sub(i,i) == 'm' then
         color = false
      end
      if k == cols then
         if str:sub(i,i) == ' ' then
            res = res .. '\n'
            k = 1
         end
      elseif not color then
         k = k + 1
      end
      if str:sub(i,i) == '\n' then
         k = 1
      end
   end
   return res
end

function dok.stylize(html, package)
   local styled = html
   -- (0) useless white space
   styled = styled:gsub('^%s+','')
   -- (1) function title
   styled = styled:gsub('<h%d>(.-)</h%d>', function(title) return style.title .. title .. style.none .. '\n' end)
   -- (2) lists
   styled = styled:gsub('<ul>(.-)</ul>', 
			function(list) 
			   return list:gsub('<li>%s*(.-)%s*</li>%s*', style.list .. '%1\n')
			end
   )
   -- (3) code
   styled = styled:gsub('%s*<code>%s*(.-)%s*</code>%s*', style.code .. ' %1 ' .. style.none)
   styled = styled:gsub('%s*<code class%="%S-">%s*(.-)%s*</code>%s*', style.pre .. ' %1 ' .. style.none)

   -- (4) pre
   styled = styled:gsub('<pre.->(.-)</pre>', style.pre .. '%1' .. style.none)

   -- (5) formatting
   styled = styled:gsub('<em>(.-)</em>', style.em .. '%1' .. style.none)
   styled = styled:gsub('<b>(.-)</b>', style.bold .. '%1' .. style.none)
   styled = styled:gsub('<strong>(.-)</strong>', style.bold .. '%1' .. style.none)
   styled = styled:gsub('//(.-)//', style.bold .. '%1' .. style.none)

   -- (6) links
   styled = styled:gsub('<a.->(.-)</a>', style.none .. '%1' .. style.none)
   -- (7) images
   styled = styled:gsub('<img.-src="(.-)".->%s*', 
			style.img .. 'image: file://' 
			   .. paths.concat(package,'%1') -- OUCH DEBUG paths.install_dokmedia,
			   .. style.none .. '\n')
   -- (8) remove internal anchors
   styled = styled:gsub('<a(.-)/>', '')
   -- (-) paragraphs
   styled = styled:gsub('<p>', '\n')
   styled = styled:gsub('</p>', '')

   -- (-) special chars
   styled = uncleanText(styled)
   -- (-) max columns
   styled = maxcols(styled)
   -- (-) conclude
   styled = styled:gsub('%s*$','')

   return styled
end

local function adddok(...)
   local tt = {}
   local arg = {...}
   for i=1,#arg do
      table.insert(tt,arg[i])
   end
   return table.concat(tt,'\n')
end

--[[
   function dok.html2funcs(html, package)
   This is how this function works:
   It initializes the section to level-0 (which means a heading with <h0>). 
   There cant be a html section higher than this, so root node.

   It looks first for an anchor, like this one:
      <a name="nn.dok"/>
   Once it found an anchor, it gets the name of the anchor, in this case it is nn.dok

   It also looks for headings, like this:
      <h1>Neural Network Package</h1>
   The level of the heading is determined by <h[number]>

   It then sees if before the heading <h1> appeared and after the 
   anchor (<a>) appeared, if any other lines were parsed. It records those 
   lines in csection (just table.insert the lines) as a string.

   Now, continuing, the level is a number. 
   It looks at if the current level is lower than the current csection's level 
   (which means is it higher up the tree towards the root). If it is, it 
   traverses up the tree until it finds the parent is one level above, so that
   it can insert the current node into the right level of the tree.
   
   Now, it creates this subsection (which depends on the anchor and heading-name.
   it inserts it into this tree appropriately.

   Then it keeps parsing lines until the lines are again either an anchor or 
   a heading. Once this happens, the subsection is deemed to be traversed and sealed.

   Then finally it creates a table of functions that have a key of the anchor 
   name, and a value of the parsed lines (after stylizing them). A small 
   check is done to make sure that the anchor name starts with the package-name.
   
]]--
function dok.html2funcs(html, package)
   local sections = {level=0}
   local csection = sections
   local canchor
   local lines = {}
   for line in html:gmatch('[^\n\r]+') do
      local anchor = line:match('<a.-name=["\'](.-)["\']/>') 
         or line:match('<a.-name=["\'](.-)["\']>.-</a>')
      local level, name = line:match('<h(%d)>(.*)</h%d>')
      if anchor then
         canchor = anchor
      elseif level and name then
         if #lines > 0 then
            table.insert(csection, table.concat(lines, '\n'))
            lines = {}
         end

         level = tonumber(level)
         if level <= csection.level then
            while level <= csection.level do
               csection = csection.parent
            end
         end

         local subsection = {level=level, parent=csection, name=name, anchor=canchor}
         table.insert(csection, subsection)
         csection = subsection

      elseif line:match('^%s+$') then
      else
         canchor = nil
         table.insert(lines, line)
      end
   end

   -- deal with remaining lines
   if #lines > 0 then
      table.insert(csection, table.concat(lines, '\n'))
      lines = {}
   end
   
   local function printsection(section, txt)
      if section.level > 0 and section.name then
         table.insert(txt, string.format('<h%d>%s</h%d>', section.level, section.name, section.level))
      end
      if section.anchor then
      end
      for i=1,#section do
         if type(section[i]) == 'string' then -- this is NOT a subsection. Do not include sub-sections in there.
            table.insert(txt, section[i])
         end
      end
   end

   local funcs = {}

   local function traversesection(section)
      if section.anchor then
         local txt = {}
         local key = string.lower(section.anchor):match(package .. '%.(.*)')
         if key then
            printsection(section, txt)
            txt = table.concat(txt, '\n')
            funcs[key] = adddok(funcs[key], dok.stylize(txt, package))
         end
      end
      for i=1,#section do
         if type(section[i]) == 'string' then
         else
            traversesection(section[i])
         end
      end
   end
   traversesection(sections)

   return funcs
end

local function packageiterator()
   local co = coroutine.create(
      function()
         local trees = mdsearchpaths
	 for _,tree in ipairs(trees) do
	    for file in paths.files(tree) do
	       if file ~= '.' and file ~= '..' then
		  coroutine.yield(file, paths.concat(tree, file))
	       end
	    end
         end
   end)

   return function()
      local code, res1, res2 = coroutine.resume(co)
      return res1, res2
   end
end

local function mditerator(path)
   local co = coroutine.create(
      function()
	 function iterate(path)
	    if path == '.' or path == '..' then
	    elseif paths.filep(path) then
	       if path:match('%.md$') then
		  coroutine.yield(path)
	       end
	    else
	       for file in paths.files(path) do
		  if file ~= '.' and file ~= '..' then
		     iterate(paths.concat(path, file))
		  end
	       end
	    end
	 end
	 iterate(path)
   end)

   return function()
      local code, res = coroutine.resume(co)
      return res
   end

end

function dok.refresh()
   for pkgname, path in packageiterator() do
      local pkgtbl = _G[pkgname] or package.loaded[pkgname]
      if pkgtbl and not knownpkg[pkgname] then
         knownpkg[pkgname] = true
         for file in mditerator(path) do
            local f = io.open(file)
            if f then
               local content = f:read('*all')
               local html = dok.markdown2html(content)
               local funcs = dok.html2funcs(html, pkgname)
               if type(pkgtbl) ~= 'table' and _G._torchimport then 
                  -- unsafe import, use protected import
                  pkgtbl = _G._torchimport[pkgname]
               end
               if pkgtbl and type(pkgtbl) == 'table' then
                  -- level 0: the package itself
                  dok.inline[pkgtbl] = dok.inline[pkgtbl] or funcs['dok'] 
		     or funcs['reference.dok'] or funcs['overview.dok']
                  -- next levels
                  for key,symb in pairs(pkgtbl) do
                     -- level 1: global functions and objects
                     local entry = (key):lower()
                     if funcs[entry] or funcs[entry..'.dok'] then
                        local sym = string2symbol(pkgname .. '.' .. key)
                        dok.inline[sym] = adddok(funcs[entry..'.dok'],funcs[entry])
                     end
                     -- level 2: objects' methods
                     if type(pkgtbl[key]) == 'table' then
                        local entries = {}
                        for k,v in pairs(pkgtbl[key]) do
                           entries[k] = v
                        end
                        local mt = getmetatable(pkgtbl[key]) or {}
                        for k,v in pairs(mt) do
                           entries[k] = v
                        end
                        for subkey,subsymb in pairs(entries) do
                           local entry = (key .. '.' .. subkey):lower()
                           if funcs[entry] or funcs[entry..'.dok'] then
                              local sym = string2symbol(pkgname .. '.' .. key .. '.' .. subkey)
                              dok.inline[sym] = adddok(funcs[entry..'.dok'],funcs[entry])
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

--------------------------------------------------------------------------------
-- help() is the main user-side function: prints help for any given
-- symbol that has an anchor defined in a .dok file.
--------------------------------------------------------------------------------
function dok.help(symbol, asstring)
   -- color detect
   if qtide then
      dok.dontusecolors()
   else
      dok.usecolors()
   end
   -- no symbol? global help
   if not symbol then
      print(style.banner)
      print(style.title .. 'help(symbol)' .. style.none 
	       .. '\n\nget inline help on a specific symbol\n'
	       .. '\nto browse the complete html documentation, call: '
	       .. style.title .. 'browse()' .. style.none)
      print(style.banner)
      return
   end
   -- always refresh (takes time, but insures that 
   -- we generate help for all packages loaded)
   dok.refresh()
   if type(symbol) == 'string' then
      symbol = string2symbol(symbol)
   end
   local inline = dok.inline[symbol]
   if asstring then
      return inline
   else
      if inline then
         print(style.banner)
         print(inline)
         print(style.banner)
      else
	 print('undocumented symbol')
      end
   end
end

rawset(_G, 'help', dok.help)

-- function to parse a package's markdown files in a different way than for help().
-- this function returns the package's markdown files names (without extension) along with their headings.
local function package_headings(pname)
   local out = {}
   for pkgname, path in packageiterator() do
      if pkgname == pname then
	 local pkgtbl = _G[pkgname] or package.loaded[pkgname]
	 if pkgtbl then
	    for file in mditerator(path) do
	       local basename = paths.basename(file)
	       basename = basename:sub(1,#basename-3) -- remove .md
	       local f = io.open(file)
	       if f then
		  local heading = 'Untitled'
		  local content = f:read('*all')
		  local html = dok.markdown2html(content)
		  -- find first heading
		  for line in html:gmatch('[^\n\r]+') do
		     local level, name = line:match('<h(%d)>(.*)</h%d>')
		     if level and name then
			heading = name
			break -- found the first heading, call it a day
		     end
		  end
		  f:close()
		  out[basename] = {heading, file}
	       end -- if f then
	    end -- for file in mditerator
	 end -- if pkgtbl
	 break;
      end -- if pkgname == pname      
   end -- for pkgname, path in packageiterator()
   return out
end

--------------------------------------------------------------------------------
-- browse() is a function that triggers a manual viewer in command-line
--------------------------------------------------------------------------------
function dok.browse(package_name)
   print(style.banner)
   print('Inline Package Manual Browser')
   print(style.banner)
   print('To exit at any time, type q or exit')
   if not package_name then
      print('Enter package name to browse (example: torch):')
      local answer = io.read()
      package_name = answer
   end
   if package_name == 'exit' then return end
   local ok, p = pcall(function() require(package_name) end)
   if not ok then
      print('Package not found or failed to load:', package_name)
      return
   end

   dok.help(package_name)
   -- Approach 1:
   -- show all available anchors from this dok and ask user to enter page.

   -- Approach 2:
   -- show file-by-file. After Overview, traverse Each file, and get the file heading. Print it out.
   -- Ask user to enter next file they want to traverse-to. (in brackets you can give them hints).

   -- Let's hack Approach 2.
   local headings = package_headings(package_name)
   
   print('Sections:')
   local example
   local menu = ''
   for k,v in pairs(headings) do
      menu = menu .. '\t' .. v[1] .. ' [' .. k .. ']\n'
      example = k
   end
   assert(example, 'No more subsections for this package')
   while true do
      print(menu)
      print('Enter choice (Example: ' .. example .. ') or type exit. :')
      local k = io.read()
      if k == 'exit'  then return end
      if headings[k] then
	 local file = headings[k][2]
	 local f = io.open(file)
	 if f then
	    local content = f:read('*all')
	    local sd = require 'sundown'
	    local str = sd.renderASCII(content)
	    local tracker = 0
	    f:close()
	    local max_chars = 1000 -- now print this string conservatively, maybe 1000 characters at a time	    
	    while tracker <= #str do
	       print(str:sub(tracker, tracker + max_chars))
	       print('[enter] for more or press any character to exit')
	       local ans = io.read()
	       if ans ~= ''  then break; end
	       tracker = tracker + max_chars
	    end
	 end
      end
   end
   
end

rawset(_G, 'browse', dok.browse)

--------------------------------------------------------------------------------
-- standard usage function: used to display automated help for functions
--
-- @param funcname     function name
-- @param description  description of the function
-- @param example      usage example
-- @param ...          [optional] arguments
--------------------------------------------------------------------------------
function dok.usage(funcname, description, example, ...)
   local str = ''

   local help = help(string2symbol(funcname), true)
   if help then
      str = str .. help
   else
      str = str .. style.banner .. '\n'
      str = str .. style.title .. funcname .. style.none .. '\n'
      if description then
         str = str .. '\n' .. description .. '\n'
      end
   end

   str = str .. '\n' .. style.list .. 'usage:\n' .. style.pre

   -- named arguments:
   local args = {...}
   if args[1].tabled then
      args = args[1].tabled 
   end
   if args[1].arg then
      str = str .. funcname .. '{\n'
      for i,param in ipairs(args) do
         local key
         if param.req then
            key = '    ' .. param.arg .. ' = ' .. param.type
         else
            key = '    [' .. param.arg .. ' = ' .. param.type .. ']'
         end
         -- align:
         while key:len() < 40 do
            key = key .. ' '
         end
         str = str .. key .. '-- ' .. param.help 
         if param.default or param.default == false then
            str = str .. '  [default = ' .. tostring(param.default) .. ']'
         elseif param.defaulta then
            str = str .. '  [default == ' .. param.defaulta .. ']'
         end
         str = str.. '\n'
      end
      str = str .. '}\n'

      -- unnamed args:
   else
      local idx = 1
      while true do
         local param
         str = str .. funcname .. '(\n'
         while true do
            param = args[idx]
            idx = idx + 1
            if not param or param == '' then break end
            local key
            if param.req then
               key = '    ' .. param.type
            else
               key = '    [' .. param.type .. ']'
            end
            -- align:
            while key:len() < 40 do
               key = key .. ' '
            end
            str = str .. key .. '-- ' .. param.help .. '\n'
         end
         str = str .. ')\n'
         if not param then break end
      end
   end
   str = str .. style.none

   if example then
      str = str .. '\n' .. style.pre .. example .. style.none .. '\n'
   end

   str = str .. style.banner
   return str
end

--------------------------------------------------------------------------------
-- standard argument function: used to handle named arguments, and 
-- display automated help for functions
--------------------------------------------------------------------------------
function dok.unpack(args, funcname, description, ...)
   -- put args in table
   local defs = {...}

   -- generate usage string as a closure:
   -- this way the function only gets called when an error occurs
   local fusage = function() 
      local example
      if #defs > 1 then
	 example = funcname .. '{' .. defs[2].arg .. '=' .. defs[2].type .. ', '
	    .. defs[1].arg .. '=' .. defs[1].type .. '}\n'
	 example = example .. funcname .. '(' .. defs[1].type .. ',' .. ' ...)'
      end
      return dok.usage(funcname, description, example, {tabled=defs})
   end
   local usage = {}
   setmetatable(usage, {__tostring=fusage})

   -- get args
   local iargs = {}
   if args.__printhelp then 
      print(usage)
      error('error')
   elseif #args == 1 and type(args[1]) == 'table' and #args[1] == 0 
   and not (torch and torch.typename(args[1]) ~= nil) then
      -- named args
      iargs = args[1]
   else
      -- ordered args
      for i = 1,select('#',...) do
         iargs[defs[i].arg] = args[i]
      end
   end

   -- check/set arguments
   local dargs = {}
   for i = 1,#defs do
      local def = defs[i]
      -- is value requested ?
      if def.req and iargs[def.arg] == nil then
         print(style.error .. 'missing argument: ' .. def.arg .. style.none)
         print(usage)
         error('error')
      end
      -- get value or default
      dargs[def.arg] = iargs[def.arg]
      if dargs[def.arg] == nil then
         dargs[def.arg] = def.default
      end
      if dargs[def.arg] == nil and def.defaulta then
         dargs[def.arg] = dargs[def.defaulta]
      end
      dargs[i] = dargs[def.arg]
   end

   -- return usage too
   dargs.usage = usage

   -- stupid lua bug: we return all args by hand
   if dargs[65] then
      error('<dok.unpack> oups, cant deal with more than 64 arguments :-)')
   end

   -- return modified args
   return dargs,unpack(dargs)
end

--------------------------------------------------------------------------------
-- prints an error with nice formatting. If domain is provided, it is used as
-- following: <domain> msg
--------------------------------------------------------------------------------
function dok.error(message, domain)
   if domain then
      message = '<' .. domain .. '> ' .. message
   end
   local col_msg = style.error .. tostring(message) .. style.none
   error(col_msg)
end
