local env = require 'argcheck.env'
local sdascii
pcall(function()
         sdascii = require 'sundown.ascii'
      end)

local function generateargp(rules)
   local txt = {}
   for idx, rule in ipairs(rules) do
      local isopt = rule.opt or rule.default ~= nil or rules.defauta or rule.defaultf
      table.insert(txt,
                   (isopt and '[' or '')
                      .. ((idx == 1) and '' or ', ')
                      .. rule.name
                      .. (isopt and ']' or ''))
   end
   return table.concat(txt)
end

local function generateargt(rules)
   local txt = {}
   table.insert(txt, '```')
   table.insert(txt, string.format(
                   '%s%s',
                   rules.noordered and '' or '(',
                   rules.nonamed and '' or '{'))

   local size = 0
   for _,rule in ipairs(rules) do
      size = math.max(size, #rule.name)
   end
   local arg = {}
   local hlp = {}
   for _,rule in ipairs(rules) do
      table.insert(arg,
                   ((rule.opt or rule.default ~= nil or rule.defaulta or rule.defaultf) and '[' or ' ')
                   .. rule.name .. string.rep(' ', size-#rule.name)
                   .. (rule.type and (' = ' .. rule.type) or '')
                .. ((rule.opt or rule.default ~= nil or rule.defaulta or rule.defaultf) and ']' or '')
          )
      local default = ''
      if rule.defaulta then
         default = string.format(' [defaulta=%s]', rule.defaulta)
      elseif rule.defaultf then
         default = string.format(' [has default]')
      elseif type(rule.default) ~= 'nil' then
         if type(rule.default) == 'string' then
            default = string.format(' [default=%s]', rule.default)
         elseif type(rule.default) == 'number' then
            default = string.format(' [default=%s]', rule.default)
         elseif type(rule.default) == 'boolean' then
            default = string.format(' [default=%s]', rule.default and 'true' or 'false')
         else
            default = ' [has default value]'
         end
      end
      table.insert(hlp, (rule.help or '') .. (rule.doc or '') .. default)
   end

   local size = 0
   for i=1,#arg do
      size = math.max(size, #arg[i])
   end

   for i=1,#arg do
      table.insert(txt, string.format("  %s %s -- %s", arg[i], string.rep(' ', size-#arg[i]), hlp[i]))
   end
   table.insert(txt, string.format(
                   '%s%s',
                   rules.nonamed and '' or '}',
                   rules.noordered and '' or ')'))
   table.insert(txt, '```')

   txt = table.concat(txt, '\n')

   return txt
end

local function usage(truth, rules, ...)
   if truth then
      local norender = select(1, ...)
      local doc = rules.help or rules.doc

      if doc then
         doc = doc:gsub('@ARGP',
                        function()
                           return generateargp(rules)
                        end)

         doc = doc:gsub('@ARGT',
                        function()
                           return generateargt(rules)
                        end)
      end

      if not doc then
         doc = '\n*Arguments:*\n' .. generateargt(rules)
      end

      if sdascii and not norender then
         doc = sdascii.render(doc)
      end

      return doc
   else
      local self = rules
      local args = {}
      for i=1,select('#', ...) do
         table.insert(args, string.format("**%s**", env.type(select(i, ...))))
      end
      local argtblidx
      if self:hasruletype('N') then
         if select("#", ...) == 1 and env.istype(select(1, ...), "table") then
            argtblidx = 1
         end
      elseif self:hasruletype('M') then
         if select("#", ...) == 2 and env.istype(select(2, ...), "table") then
            argtblidx = 2
         end
      end
      if argtblidx then
         local argtbl = {}
         local tbl = select(argtblidx, ...)
         local n = 0
         for k,v in pairs(tbl) do
            n = n + 1
            if n > 20 then
               table.insert(argtbl, '...')
               break
            end
            if type(k) == 'string' then
               table.insert(argtbl, string.format("**%s=%s**", k, env.type(v)))
            else
               table.insert(argtbl, string.format("**[%s]**=?", env.type(k)))
            end
         end
         args[argtblidx] = string.format("**table**={ %s }", table.concat(argtbl, ', '))
      end
      local doc = string.format("*Got:* %s", table.concat(args, ', '))
      if sdascii then
         doc = sdascii.render(doc)
      end
      return doc
   end
end

return usage
