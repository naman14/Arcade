local utils = {}

function utils.setupvalue(func, name, newvalue, quiet)
   local uidx = 0
   repeat
      uidx = uidx + 1
      local uname, value = debug.getupvalue(func, uidx)
      if uname == name then
         debug.setupvalue(func, uidx, newvalue)
         return value -- previous one
      end
   until uname == nil
   if not quiet then
      error(string.format('unknown upvalue <%s>', name))
   end
end

function utils.getupvalue(func, name, quiet)
   local uidx = 0
   repeat
      uidx = uidx + 1
      local uname, value = debug.getupvalue(func, uidx)
      if uname == name then
         return value
      end
   until uname == nil
   if not quiet then
      error(string.format('unknown upvalue <%s>', name))
   end
end

function utils.duptable(tbl)
   local dup = {}
   for k,v in pairs(tbl) do
      dup[k] = v
   end
   return dup
end

return utils
