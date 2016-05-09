local ffi = require 'ffi'

local sundown = {}

-- Compat function from https://github.com/stevedonovan/Penlight/blob/master/lua/pl/compat.lua
if not package.searchpath then
   local sep = package.config:sub(1,1)
   function package.searchpath (mod,path)
      mod = mod:gsub('%.',sep)
      for m in path:gmatch('[^;]+') do
         local nm = m:gsub('?',mod)
         local f = io.open(nm,'r')
         if f then f:close(); return nm end
        end
    end
end

sundown.C = ffi.load(package.searchpath('libsundown', package.cpath))

return sundown
