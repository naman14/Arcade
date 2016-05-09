local env = {}

-- user configurable function
function env.istype(obj, typename)
   local mt = getmetatable(obj)
   if type(mt) == 'table' then
      local objtype = rawget(mt, '__typename')
      if objtype then
         return objtype == typename
      end
   end
   return type(obj) == typename
end

function env.type(obj)
   local mt = getmetatable(obj)
   if type(mt) == 'table' then
      local objtype = rawget(mt, '__typename')
      if objtype then
         return objtype
      end
   end
   return type(obj)
end

-- torch specific
if pcall(require, 'torch') then
   function env.istype(obj, typename)
      local thname = torch.typename(obj)
      if thname then
         -- __typename (see below) might be absent
         local match = thname:match(typename)
         if match and (match ~= typename or match == thname) then
            return true
         end
         local mt = torch.getmetatable(thname)
         while mt do
            if mt.__typename then
                match = mt.__typename:match(typename)
                if match and (match ~= typename or match == mt.__typename) then
                   return true
                end
            end
            mt = getmetatable(mt)
         end
         return false
      end
      return type(obj) == typename
   end
   function env.type(obj)
      return torch.type(obj)
   end
end

return env
