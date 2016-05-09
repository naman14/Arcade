----------------------------------------------------------------------
--
-- Copyright (c) 2011 Clement Farabet
--           (c) 2008 David Manura (for the OptionParser)
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- 
----------------------------------------------------------------------
-- description:
--     xlua - a package that provides a better Lua prompt, and a few
--            methods to deal with the namespace, argument unpacking
--            and so on...
--
-- history: 
--     July  7, 2011, 12:49AM - added OptionParser from D. Manura
--     June 30, 2011, 4:54PM - creation - Clement Farabet
----------------------------------------------------------------------

local os = require 'os'
local sys = require 'sys'
local io = require 'io'
local math = require 'math'
local torch = require 'torch'

xlua = {}
local _protect_ = {}
for k,v in pairs(_G) do
   table.insert(_protect_, k)
end

-- extra files
require 'xlua.OptionParser'
require 'xlua.Profiler'


----------------------------------------------------------------------
-- better print function
----------------------------------------------------------------------
function xlua.print(obj,...)
   if type(obj) == 'table' then
      local mt = getmetatable(obj)
      if mt and mt.__tostring__ then
         io.write(mt.__tostring__(obj))
      else
         local tos = tostring(obj)
         local obj_w_usage = false
         if tos and not string.find(tos,'table: ') then
            if obj.usage and type(obj.usage) == 'string' then
               io.write(obj.usage)
               io.write('\n\nFIELDS:\n')
               obj_w_usage = true
            else
               io.write(tos .. ':\n')
            end
         end
         io.write('{')
         local tab = ''
         local idx = 1
         for k,v in pairs(obj) do
            if idx > 1 then io.write(',\n') end
            if type(v) == 'userdata' then
               io.write(tab .. '[' .. k .. ']' .. ' = <userdata>')
            else
               local tostr = tostring(v):gsub('\n','\\n')
               if #tostr>40 then
                  local tostrshort = tostr:sub(1,40) .. sys.COLORS.none
                  io.write(tab .. '[' .. tostring(k) .. ']' .. ' = ' .. tostrshort .. ' ... ')
               else
                  io.write(tab .. '[' .. tostring(k) .. ']' .. ' = ' .. tostr)
               end
            end
            tab = ' '
            idx = idx + 1
         end
         io.write('}')
         if obj_w_usage then
            io.write('')
         end
      end
   else
      io.write(tostring(obj))
   end
   if select('#',...) > 0 then
      io.write('    ')
      print(...)
   else
      io.write('\n')
   end
end
rawset(_G, 'xprint', xlua.print)

----------------------------------------------------------------------
-- log all session, by replicating stdout to a file
----------------------------------------------------------------------
function xlua.log(file, append)
   os.execute('mkdir ' .. (sys.uname() ~= 'windows' and '-p ' or '') .. ' "' .. sys.dirname(file) .. '"')
   local mode = 'w'
   if append then mode = 'a' end
   local f = assert(io.open(file,mode))
   io._write = io.write
   _G._print = _G.print
   _G.print = xlua.print
   io.write = function(...)
                      io._write(...)
                      local arg = {...}
                      for i = 1,select('#',...) do
                         f:write(arg[i])
                      end
                      f:flush()
                   end
end

----------------------------------------------------------------------
-- clear all globals
----------------------------------------------------------------------
function xlua.clearall()
   for k,v in pairs(_G) do
      local protected = false
      local lib = false
      for i,p in ipairs(_protect_) do
         if k == p then protected = true end
      end
      for p in pairs(package.loaded) do
         if k == p then lib = true end
      end
      if not protected then
         _G[k] = nil
         if lib then package.loaded[k] = nil end
      end
   end
   collectgarbage()
end

----------------------------------------------------------------------
-- clear one variable
----------------------------------------------------------------------
function xlua.clear(var)
   _G[var] = nil
   collectgarbage()
end

----------------------------------------------------------------------
-- prints globals
----------------------------------------------------------------------
function xlua.who()
   local user = {}
   local libs = {}
   for k,v in pairs(_G) do
      local protected = false
      local lib = false
      for i,p in ipairs(_protect_) do
         if k == p then protected = true end
      end
      for p in pairs(package.loaded) do
         if k == p and p ~= '_G' then lib = true end
      end
      if lib then
         table.insert(libs, k)
      elseif not protected then
         user[k] =  _G[k]
      end
   end
   xlua.print('')
   xlua.print('Global Libs:')
   xlua.print(libs)
   xlua.print('')
   xlua.print('Global Vars:')
   xlua.print(user)
   xlua.print('')
end

----------------------------------------------------------------------
-- time
----------------------------------------------------------------------
function xlua.formatTime(seconds)
   -- decompose:
   local floor = math.floor
   local days = floor(seconds / 3600/24)
   seconds = seconds - days*3600*24
   local hours = floor(seconds / 3600)
   seconds = seconds - hours*3600
   local minutes = floor(seconds / 60)
   seconds = seconds - minutes*60
   local secondsf = floor(seconds)
   seconds = seconds - secondsf
   local millis = floor(seconds*1000)

   -- string
   local f = ''
   local i = 1
   if days > 0 then f = f .. days .. 'D' i=i+1 end
   if hours > 0 and i <= 2 then f = f .. hours .. 'h' i=i+1 end
   if minutes > 0 and i <= 2 then f = f .. minutes .. 'm' i=i+1 end
   if secondsf > 0 and i <= 2 then f = f .. secondsf .. 's' i=i+1 end
   if millis > 0 and i <= 2 then f = f .. millis .. 'ms' i=i+1 end
   if f == '' then f = '0ms' end

   -- return formatted time
   return f
end
local formatTime = xlua.formatTime

----------------------------------------------------------------------
-- progress bar
----------------------------------------------------------------------
do
   local function getTermLength()
      if sys.uname() == 'windows' then return 80 end
      local tputf = io.popen('tput cols', 'r')
      local w = tonumber(tputf:read('*a'))
      local rc = {tputf:close()}
      if rc[3] == 0 then return w
      else return 80 end 
   end

   local barDone = true
   local previous = -1
   local tm = ''
   local timer
   local times
   local indices
   local termLength = math.min(getTermLength(), 120)
   function xlua.progress(current, goal)
      -- defaults:
      local barLength = termLength - 34
      local smoothing = 100 
      local maxfps = 10
      
      -- Compute percentage
      local percent = math.floor(((current) * barLength) / goal)

      -- start new bar
      if (barDone and ((previous == -1) or (percent < previous))) then
         barDone = false
         previous = -1
         tm = ''
         timer = torch.Timer()
         times = {timer:time().real}
         indices = {current}
      else
         io.write('\r')
      end

      --if (percent ~= previous and not barDone) then
      if (not barDone) then
         previous = percent
         -- print bar
         io.write(' [')
         for i=1,barLength do
            if (i < percent) then io.write('=')
            elseif (i == percent) then io.write('>')
            else io.write('.') end
         end
         io.write('] ')
         for i=1,termLength-barLength-4 do io.write(' ') end
         for i=1,termLength-barLength-4 do io.write('\b') end
         -- time stats
         local elapsed = timer:time().real
         local step = (elapsed-times[1]) / (current-indices[1])
         if current==indices[1] then step = 0 end
         local remaining = math.max(0,(goal - current)*step)
         table.insert(indices, current)
         table.insert(times, elapsed)
         if #indices > smoothing then
            indices = table.splice(indices)
            times = table.splice(times)
         end
         -- Print remaining time when running or total time when done.
         if (percent < barLength) then
            tm = ' ETA: ' .. formatTime(remaining)
         else
            tm = ' Tot: ' .. formatTime(elapsed)
         end
         tm = tm .. ' | Step: ' .. formatTime(step)
         io.write(tm)
         -- go back to center of bar, and print progress
         for i=1,5+#tm+barLength/2 do io.write('\b') end
         io.write(' ', current, '/', goal, ' ')
         -- reset for next bar
         if (percent == barLength) then
            barDone = true
            io.write('\n')
         end
         -- flush
         io.write('\r')
         io.flush()
      end
   end
end

--------------------------------------------------------------------------------
-- prints an error with nice formatting. If domain is provided, it is used as
-- following: <domain> msg
--------------------------------------------------------------------------------
function xlua.error(message, domain, usage)
   local c = sys.COLORS
   if domain then
      message = '<' .. domain .. '> ' .. message
   end
   local col_msg = c.Red .. tostring(message) .. c.none
   if usage then
      col_msg = col_msg .. '\n' .. usage
   end
   error(col_msg)
end
rawset(_G, 'xerror', xlua.error)

--------------------------------------------------------------------------------
-- provides standard try/catch functions
--------------------------------------------------------------------------------
function xlua.trycatch(try,catch)
   local ok,err = pcall(try)
   if not ok then catch(err) end
end

--------------------------------------------------------------------------------
-- returns true if package is installed, rather than crashing stupidly :-)
--------------------------------------------------------------------------------
function xlua.installed(package)
   local found = false
   local p = package.path .. ';' .. package.cpath
   for path in p:gfind('.-;') do
      path = path:gsub(';',''):gsub('?',package)
      if sys.filep(path) then
         found = true
         p = path
         break
      end
   end
   return found,p
end

--------------------------------------------------------------------------------
-- try to load a package, and doesn't crash if not found !
-- optionally try to install it from luarocks, and then load it.
--
-- @param package      package to load
-- @param luarocks     if true, then try to install missing package with luarocks
-- @param server       specify a luarocks server
--------------------------------------------------------------------------------
function xlua.require(package,luarocks,server)
   local loaded
   local load = function() loaded = require(package) end
   local ok,err = pcall(load)
   if not ok then
      print(err)
      print('warning: <' .. package .. '> could not be loaded (is it installed?)')
      return false
   end
   return loaded
end
rawset(_G, 'xrequire', xlua.require)



--http://lua-users.org/wiki/TableUtils
local function table_val_to_str ( v )
   if "string" == type( v ) then
      v = string.gsub( v, "\n", "\\n" )
      if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
         return "'" .. v .. "'"
      end
      return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
   else
      return "table" == type( v ) and xlua.table2string( v ) or tostring( v )
   end
end

local function table_key_to_str ( k )
   if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
      return k
   else
      return "[" .. table_val_to_str( k ) .. "]"
   end
end

function xlua.table2string(tbl, newline)
   local result, done = {}, {}
   for k, v in ipairs( tbl ) do
      table.insert( result, table_val_to_str( v ) )
      done[ k ] = true
   end
   local s = "="
   if newline then
      s = " : "
   end
   for k, v in pairs( tbl ) do
      if not done[ k ] then
         local line = table_key_to_str( k ) .. s .. table_val_to_str( v )
         table.insert(result, line)
      end
   end
   local res
   if newline then
      res = "{\n   " .. table.concat( result, "\n   " ) .. "\n}"
   else
      res = "{" .. table.concat( result, "," ) .. "}"
   end
   return res
end


--------------------------------------------------------------------------------
-- standard usage function: used to display automated help for functions
--
-- @param funcname     function name
-- @param description  description of the function
-- @param example      usage example
-- @param ...          [optional] arguments
--------------------------------------------------------------------------------
function xlua.usage(funcname, description, example, ...)
   local c = sys.COLORS

   local style = {
      banner = '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++',
      list = c.blue .. '> ' .. c.none,
      title = c.Magenta,
      pre = c.cyan,
      em = c.Black,
      img = c.red,
      link = c.red,
      code = c.green,
      none = c.none
   }

   local str = style.banner .. '\n'

   str = str .. style.title .. funcname .. style.none .. '\n'
   if description then
      str = str .. '\n' .. description .. '\n'
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
         if type(param.default) == 'table' then
            str = str .. '  [default = ' .. xlua.table2string(param.default) .. ']'
         elseif param.default or param.default == false then
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
function xlua.unpack(args, funcname, description, ...)
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
                     return xlua.usage(funcname, description, example, {tabled=defs})
                  end
   local usage = {}
   setmetatable(usage, {__tostring=fusage})

   -- get args
   local iargs = {}
   if #args == 0 then
      print(usage)
      xlua.error('error')
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
         local c = sys.COLORS
         print(c.Red .. 'missing argument: ' .. def.arg .. c.none)
         print(usage)
         xlua.error('error')
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
      xlua.error('<xlua.unpack> oups, cant deal with more than 64 arguments :-)')
   end

   -- return modified args
   return dargs,
   dargs[1], dargs[2], dargs[3], dargs[4], dargs[5], dargs[6], dargs[7], dargs[8], 
   dargs[9], dargs[10], dargs[11], dargs[12], dargs[13], dargs[14], dargs[15], dargs[16],
   dargs[17], dargs[18], dargs[19], dargs[20], dargs[21], dargs[22], dargs[23], dargs[24],
   dargs[25], dargs[26], dargs[27], dargs[28], dargs[29], dargs[30], dargs[31], dargs[32],
   dargs[33], dargs[34], dargs[35], dargs[36], dargs[37], dargs[38], dargs[39], dargs[40],
   dargs[41], dargs[42], dargs[43], dargs[44], dargs[45], dargs[46], dargs[47], dargs[48],
   dargs[49], dargs[50], dargs[51], dargs[52], dargs[53], dargs[54], dargs[55], dargs[56],
   dargs[57], dargs[58], dargs[59], dargs[60], dargs[61], dargs[62], dargs[63], dargs[64]
end

--------------------------------------------------------------------------------
-- standard argument function for classes: used to handle named arguments, and 
-- display automated help for functions
-- auto inits the self with usage
--------------------------------------------------------------------------------
function xlua.unpack_class(object, args, funcname, description, ...)
   local dargs = xlua.unpack(args, funcname, description, ...)
   for k,v in pairs(dargs) do
      if type(k) ~= 'number' then
         object[k] = v
      end
   end
end

--------------------------------------------------------------------------------
-- module help function
--
-- @param module       module
-- @param name         module name
-- @param description  description of the module
--------------------------------------------------------------------------------
function xlua.usage_module(module, name, description)
   local c = sys.COLORS
   local hasglobals = false
   local str = c.magenta
   local str = str .. '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
   str = str .. 'PACKAGE:\n' .. name .. '\n'
   if description then
      str = str .. '\nDESC:\n' .. description .. '\n'
   end
   str = str .. '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
   str = str .. c.none
   -- register help
   local mt = getmetatable(module) or {}
   setmetatable(module,mt)
   mt.__tostring = function() return str end
   return str
end

--------------------------------------------------------------------------------
-- splicing: remove elements from a table
--------------------------------------------------------------------------------
function table.splice(tbl, start, length)
   length = length or 1
   start = start or 1
   local endd = start + length
   local spliced = {}
   local remainder = {}
   for i,elt in ipairs(tbl) do
      if i < start or i >= endd then
         table.insert(spliced, elt)
      else
         table.insert(remainder, elt)
      end
   end
   return spliced, remainder
end

--------------------------------------------------------------------------------
-- prune: remove duplicates from a table
-- if a hash function is provided, it is used to produce a unique hash for each
-- element in the input table.
-- if a merge function is provided, it defines how duplicate entries are merged,
-- otherwise, a random entry is picked.
--------------------------------------------------------------------------------
function table.prune(tbl, hashfunc, merge)
   local hashes = {}
   local hash = hashfunc or function(a) return a end
   if merge then
      for i,v in ipairs(tbl) do
         if not hashes[hash(v)] then 
            hashes[hash(v)] = v
         else
            hashes[hash(v)] = merge(v, hashes[hash(v)])
         end
      end
   else
      for i,v in ipairs(tbl) do
         hashes[hash(v)] = v
      end
   end
   local ntbl = {}
   for _,v in pairs(hashes) do
      table.insert(ntbl, v)
   end
   return ntbl
end

--------------------------------------------------------------------------------
-- split a string using a pattern
--------------------------------------------------------------------------------
function string.split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

--------------------------------------------------------------------------------
-- eval: just a shortcut to parse strings into symbols
-- example: 
-- assert( string.tosymbol('madgraph.Image.File') == madgraph.Image.File )
--------------------------------------------------------------------------------
function string.tosymbol(str)
   local ok,result = pcall(loadstring('return ' .. str))
   if not ok then
      error(result)
   elseif not result then
      error('symbol "' .. str .. '" does not exist')
   else
      return result
   end
end


--------------------------------------------------------------------------------
-- parses arguments passed as ENV variables
-- example: 
-- learningRate=1e-3 nesterov=false th train.lua
-- opt = xlua.envparams{learningRate=1e-2, nesterov=true}
--------------------------------------------------------------------------------
function xlua.envparams(default)
    local params = {}
    for k, v in pairs(default) do
        params[k] = v
        if os.getenv(k) ~= nil then
            local v_new = os.getenv(k)
            if type(v) == "number" then
              v_new = tonumber(v_new)
            end
            if type(v) == "boolean" then
              if v_new == "false" or v_new == "False" then
                  v_new = false
              elseif v_new == "true" or v_new == "True" then
                  v_new = true
              end
            end
            assert(v_new ~= nil)
            params[k] = v_new
        end
    end
    return params
end

return xlua
