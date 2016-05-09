--------------------------------------------------------------------------------
-- always returns the path of the file running
--------------------------------------------------------------------------------
local function fpath()
   local fpath = _G.debug.getinfo(2).source:gsub('@','')
   if fpath:find('/') ~= 1 then fpath = paths.concat(paths.cwd(),fpath) end
   return paths.dirname(fpath),paths.basename(fpath)
end

return fpath
