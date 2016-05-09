local CInterface = {}

function CInterface.new()
   self = {}
   self.txt = {}
   self.registry = {}
   self.defaultArguments = {}
   setmetatable(self, {__index=CInterface})
   return self
end

function CInterface:luaname2wrapname(name)
   return string.format("wrapper_%s", name)
end

function CInterface:print(str)
   table.insert(self.txt, str)
end

function CInterface:registerDefaultArgument(code)
  table.insert(self.defaultArguments, code)
end

function CInterface:wrap(luaname, ...)
   local txt = self.txt
   local varargs = {...}

   assert(#varargs > 0 and #varargs % 2 == 0, 'must provide both the C function name and the corresponding arguments')

   -- add function to the registry
   table.insert(self.registry, {name=luaname, wrapname=self:luaname2wrapname(luaname)})

   self:__addchelpers()

   table.insert(txt, string.format("static int %s(lua_State *L)", self:luaname2wrapname(luaname)))
   table.insert(txt, "{")
   table.insert(txt, "int narg = lua_gettop(L);")

   for i, defaultArgCode in ipairs(self.defaultArguments) do
      table.insert(txt, defaultArgCode(string.format("default_arg%d", i)))
   end

   if #varargs == 2 then
      local cfuncname = varargs[1]
      local args = varargs[2]

      local helpargs, cargs, argcreturned = self:__writeheaders(txt, args)
      self:__writechecks(txt, args)

      table.insert(txt, 'else')
      table.insert(txt, '{')
      table.insert(txt, string.format('char type_buf[512];'))
      table.insert(txt, string.format('str_arg_types(L, type_buf, 512);'))
      table.insert(txt, string.format('luaL_error(L, "invalid arguments: %%s\\nexpected arguments: %s", type_buf);',
            table.concat(helpargs, ' ')))
      table.insert(txt, '}')

      self:__writecall(txt, args, cfuncname, cargs, argcreturned)
   else
      local allcfuncname = {}
      local allargs = {}
      local allhelpargs = {}
      local allcargs = {}
      local allargcreturned = {}

      table.insert(txt, "int argset = 0;")

      for k=1,#varargs/2 do
         allcfuncname[k] = varargs[(k-1)*2+1]
         allargs[k] = varargs[(k-1)*2+2]
      end

      local argoffset = 0
      for k=1,#varargs/2 do
         allhelpargs[k], allcargs[k], allargcreturned[k] = self:__writeheaders(txt, allargs[k], argoffset)
         argoffset = argoffset + #allargs[k]
      end

      for k=1,#varargs/2 do
         self:__writechecks(txt, allargs[k], k)
      end

      table.insert(txt, 'else')
      local allconcathelpargs = {}
      for k=1,#varargs/2 do
         table.insert(allconcathelpargs, table.concat(allhelpargs[k], ' '))
      end
      table.insert(txt, '{')
      table.insert(txt, string.format('char type_buf[512];'))
      table.insert(txt, string.format('str_arg_types(L, type_buf, 512);'))
      table.insert(txt, string.format('luaL_error(L, "invalid arguments: %%s\\nexpected arguments: %s", type_buf);',
            table.concat(allconcathelpargs, ' | ')))
      table.insert(txt, '}')

      for k=1,#varargs/2 do
         if k == 1 then
            table.insert(txt, string.format('if(argset == %d)', k))
         else
            table.insert(txt, string.format('else if(argset == %d)', k))
         end
         table.insert(txt, '{')
         self:__writecall(txt, allargs[k], allcfuncname[k], allcargs[k], allargcreturned[k])
         table.insert(txt, '}')
      end

      table.insert(txt, 'return 0;')
   end

   table.insert(txt, '}')
   table.insert(txt, '')
end

function CInterface:__addchelpers()
    if not self.__chelpers_added then
       local txt = self.txt
       table.insert(txt, '#ifndef _CWRAP_STR_ARG_TYPES_4821726c1947cdf3eebacade98173939')
       table.insert(txt, '#define _CWRAP_STR_ARG_TYPES_4821726c1947cdf3eebacade98173939')
       table.insert(txt, '#include "string.h"')
       table.insert(txt, 'static void str_arg_types(lua_State *L, char *buf, int n) {')
       table.insert(txt, '    int i;')
       table.insert(txt, '  int nargs = lua_gettop(L);')
       table.insert(txt, '  if (nargs == 0) {')
       table.insert(txt, '    snprintf(buf, n, "no arguments provided");')
       table.insert(txt, '    return;')
       table.insert(txt, '  }')
       table.insert(txt, '  for (i = 1; i <= nargs; i++) {')
       table.insert(txt, '    int l;')
       table.insert(txt, '    const char *torch_type = luaT_typename(L, i);')
       table.insert(txt, '    if(torch_type && !strncmp(torch_type, "torch.", 6)) torch_type += 6;')
       table.insert(txt, '    if (torch_type) l = snprintf(buf, n, "%s ", torch_type);')
       table.insert(txt, '    else if(lua_isnil(L, i)) l = snprintf(buf, n, "%s ", "nil");')
       table.insert(txt, '    else if(lua_isboolean(L, i)) l = snprintf(buf, n, "%s ", "boolean");')
       table.insert(txt, '    else if(lua_isnumber(L, i)) l = snprintf(buf, n, "%s ", "number");')
       table.insert(txt, '    else if(lua_isstring(L, i)) l = snprintf(buf, n, "%s ", "string");')
       table.insert(txt, '    else if(lua_istable(L, i)) l = snprintf(buf, n, "%s ", "table");')
       table.insert(txt, '    else if(lua_isuserdata(L, i)) l = snprintf(buf, n, "%s ", "userdata");')
       table.insert(txt, '    else l = snprintf(buf, n, "%s ", "???");')
       table.insert(txt, '    if (l >= n) return;')
       table.insert(txt, '    buf += l;')
       table.insert(txt, '    n   -= l;')
       table.insert(txt, '  }')
       table.insert(txt, '}')
       table.insert(txt, '#endif')

       self.__chelpers_added = true
    end
end

function CInterface:register(name)
   local txt = self.txt
   table.insert(txt, string.format('static const struct luaL_Reg %s [] = {', name))
   for _,reg in ipairs(self.registry) do
      table.insert(txt, string.format('{"%s", %s},', reg.name, reg.wrapname))
   end
   table.insert(txt, '{NULL, NULL}')
   table.insert(txt, '};')
   table.insert(txt, '')
   self.registry = {}
end

function CInterface:clearhistory()
   self.txt = {}
   self.registry = {}
   self.defaultArguments = {}
end

function CInterface:tostring()
   return table.concat(self.txt, '\n')
end

function CInterface:tofile(filename)
   local f = io.open(filename, 'w')
   f:write(table.concat(self.txt, '\n'))
   f:close()
end

local function bit(p)
   return 2 ^ (p - 1)  -- 1-based indexing
end

local function hasbit(x, p)
   return x % (p + p) >= p
end

local function beautify(txt)
   local indent = 0
   for i=1,#txt do
      if txt[i]:match('}') then
         indent = indent - 2
      end
      if indent > 0 then
         txt[i] = string.rep(' ', indent) .. txt[i]
      end
      if txt[i]:match('{') then
         indent = indent + 2
      end
   end
end

local function tableinsertcheck(tbl, stuff)
   if stuff and not stuff:match('^%s*$') then
      table.insert(tbl, stuff)
   end
end

function CInterface:__writeheaders(txt, args, argoffset)
   local argtypes = self.argtypes
   local helpargs = {}
   local cargs = {}
   local argcreturned
   argoffset = argoffset or 0

   for i,arg in ipairs(args) do
      arg.i = i+argoffset
      arg.args = args -- in case we want to do stuff depending on other args
      assert(argtypes[arg.name], 'unknown type ' .. arg.name)
      setmetatable(arg, {__index=argtypes[arg.name]})
      arg.__metatable = argtypes[arg.name]
      tableinsertcheck(txt, arg:declare())
      local helpname = arg:helpname()
      if arg.returned then
         helpname = string.format('*%s*', helpname)
      end
      if arg.invisible and arg.default == nil then
         error('Invisible arguments must have a default! How could I guess how to initialize it?')
      end
      if arg.default ~= nil then
         if not arg.invisible then
            table.insert(helpargs, string.format('[%s]', helpname))
         end
      elseif not arg.creturned then
         table.insert(helpargs, helpname)
      end
      if arg.creturned then
         if argcreturned then
            error('A C function can only return one argument!')
         end
         if arg.default ~= nil then
            error('Obviously, an "argument" returned by a C function cannot have a default value')
         end
         if arg.returned then
            error('Options "returned" and "creturned" are incompatible')
         end
         argcreturned = arg
      else
         table.insert(cargs, arg:carg())
      end
   end

   return helpargs, cargs, argcreturned
end

function CInterface:__writechecks(txt, args, argset)
   local argtypes = self.argtypes

   local multiargset = argset
   argset = argset or 1

   local nopt = 0
   for i,arg in ipairs(args) do
      if arg.default ~= nil and not arg.invisible then
         nopt = nopt + 1
      end
   end

   for variant=0,(2^nopt)-1 do
      local opt = 0
      local currentargs = {}
      local optargs = {}
      local hasvararg = false
      for i,arg in ipairs(args) do
         if arg.invisible then
            table.insert(optargs, arg)
         elseif arg.default ~= nil then
            opt = opt + 1
            if hasbit(variant, bit(opt)) then
               table.insert(currentargs, arg)
            else
               table.insert(optargs, arg)
            end
         elseif not arg.creturned then
            table.insert(currentargs, arg)
         end
      end

      for _,arg in ipairs(args) do
         if arg.vararg then
            if hasvararg then
               error('Only one argument can be a "vararg"!')
            end
            hasvararg = true
         end
      end

      if hasvararg and not currentargs[#currentargs].vararg then
         error('Only the last argument can be a "vararg"')
      end

      local compop
      if hasvararg then
         compop = '>='
      else
         compop = '=='
      end

      if variant == 0 and argset == 1 then
         table.insert(txt, string.format('if(narg %s %d', compop, #currentargs))
      else
         table.insert(txt, string.format('else if(narg %s %d', compop, #currentargs))
      end

      for stackidx, arg in ipairs(currentargs) do
         table.insert(txt, string.format("&& %s", arg:check(stackidx)))
      end
      table.insert(txt, ')')
      table.insert(txt, '{')

      if multiargset then
         table.insert(txt, string.format('argset = %d;', argset))
      end

      for stackidx, arg in ipairs(currentargs) do
         tableinsertcheck(txt, arg:read(stackidx))
      end

      for _,arg in ipairs(optargs) do
         tableinsertcheck(txt, arg:init())
      end

      table.insert(txt, '}')

   end
end

function CInterface:__writecall(txt, args, cfuncname, cargs, argcreturned)
   local argtypes = self.argtypes

   for i = 1, #self.defaultArguments do
      table.insert(cargs, i, string.format('default_arg%d', i))
   end

   for _,arg in ipairs(args) do
      tableinsertcheck(txt, arg:precall())
   end

   if argcreturned then
      table.insert(txt, string.format('%s = %s(%s);', argtypes[argcreturned.name].creturn(argcreturned), cfuncname, table.concat(cargs, ',')))
   else
      table.insert(txt, string.format('%s(%s);', cfuncname, table.concat(cargs, ',')))
   end

   for _,arg in ipairs(args) do
      tableinsertcheck(txt, arg:postcall())
   end

   local nret = 0
   if argcreturned then
      nret = nret + 1
   end
   for _,arg in ipairs(args) do
      if arg.returned then
         nret = nret + 1
      end
   end
   table.insert(txt, string.format('return %d;', nret))
end

return CInterface
