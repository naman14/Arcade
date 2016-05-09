local argtypes = {}

local function interpretdefaultvalue(arg)
   local default = arg.default
   if type(default) == 'boolean' then
      if default then
         return '1'
      else
         return '0'
      end
   elseif type(default) == 'number' then
      return tostring(default)
   elseif type(default) == 'string' then
      return default
   elseif type(default) == 'function' then
      default = default(arg)
      assert(type(default) == 'string', 'a default function must return a string')
      return default
   elseif type(default) == 'nil' then
      return nil
   else
      error('unknown default type value')
   end   
end

argtypes.index = {

   helpname = function(arg)
               return "index"
            end,

   declare = function(arg)
                -- if it is a number we initialize here
                local default = tonumber(interpretdefaultvalue(arg)) or 1
                return string.format("long arg%d = %d;", arg.i, tonumber(default)-1)
           end,

   check = function(arg, idx)
              return string.format("lua_isnumber(L, %d)", idx)
           end,

   read = function(arg, idx)
             return string.format("arg%d = (long)lua_tonumber(L, %d)-1;", arg.i, idx)
          end,

   init = function(arg)
             -- otherwise do it here
             if arg.default then
                local default = interpretdefaultvalue(arg)
                if not tonumber(default) then
                   return string.format("arg%d = %s-1;", arg.i, default)
                end
             end
          end,

   carg = function(arg)
             return string.format('arg%d', arg.i)
          end,

   creturn = function(arg)
                return string.format('arg%d', arg.i)
             end,

   precall = function(arg)
                if arg.returned then
                   return string.format('lua_pushnumber(L, (lua_Number)arg%d+1);', arg.i)
                end
             end,

   postcall = function(arg)
                 if arg.creturned then
                    return string.format('lua_pushnumber(L, (lua_Number)arg%d+1);', arg.i)
                 end
              end
}

for _,typename in ipairs({"real", "unsigned char", "char", "short", "int", "long", "float", "double"}) do
   argtypes[typename] = {

      helpname = function(arg)
                    return typename
                 end,

      declare = function(arg)
                   -- if it is a number we initialize here
                   local default = tonumber(interpretdefaultvalue(arg)) or 0
                   return string.format("%s arg%d = %g;", typename, arg.i, default)
                end,

      check = function(arg, idx)
                 return string.format("lua_isnumber(L, %d)", idx)
              end,

      read = function(arg, idx)
                return string.format("arg%d = (%s)lua_tonumber(L, %d);", arg.i, typename, idx)
             end,

      init = function(arg)
                -- otherwise do it here
                if arg.default then
                   local default = interpretdefaultvalue(arg)
                   if not tonumber(default) then
                      return string.format("arg%d = %s;", arg.i, default)
                   end
                end
             end,
      
      carg = function(arg)
                return string.format('arg%d', arg.i)
             end,

      creturn = function(arg)
                   return string.format('arg%d', arg.i)
                end,
      
      precall = function(arg)
                   if arg.returned then
                      return string.format('lua_pushnumber(L, (lua_Number)arg%d);', arg.i)
                   end
                end,
      
      postcall = function(arg)
                    if arg.creturned then
                       return string.format('lua_pushnumber(L, (lua_Number)arg%d);', arg.i)
                    end
                 end
   }
end

argtypes.byte = argtypes['unsigned char']

argtypes.boolean = {

   helpname = function(arg)
                 return "boolean"
              end,

   declare = function(arg)
                -- if it is a number we initialize here
                local default = tonumber(interpretdefaultvalue(arg)) or 0
                return string.format("int arg%d = %d;", arg.i, tonumber(default))
             end,

   check = function(arg, idx)
              return string.format("lua_isboolean(L, %d)", idx)
           end,

   read = function(arg, idx)
             return string.format("arg%d = lua_toboolean(L, %d);", arg.i, idx)
          end,

   init = function(arg)
             -- otherwise do it here
             if arg.default then
                local default = interpretdefaultvalue(arg)
                if not tonumber(default) then
                   return string.format("arg%d = %s;", arg.i, default)
                end
             end
          end,

   carg = function(arg)
             return string.format('arg%d', arg.i)
          end,

   creturn = function(arg)
                return string.format('arg%d', arg.i)
             end,

   precall = function(arg)
                if arg.returned then
                   return string.format('lua_pushboolean(L, arg%d);', arg.i)
                end
             end,

   postcall = function(arg)
                 if arg.creturned then
                    return string.format('lua_pushboolean(L, arg%d);', arg.i)
                 end
              end
}

return argtypes
