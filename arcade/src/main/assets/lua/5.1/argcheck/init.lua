local env = require 'argcheck.env'
local utils = require 'argcheck.utils'
local doc = require 'argcheck.doc'
local usage = require 'argcheck.usage'
local ACN = require 'argcheck.graph'

local setupvalue = utils.setupvalue
local getupvalue = utils.getupvalue
local loadstring = loadstring or load

local function generaterules(rules)
   local graph
   if rules.chain or rules.overload then
      local status
      status, graph = pcall(getupvalue, rules.chain or rules.overload, 'graph')
      if not status then
         error('trying to overload a non-argcheck function')
      end
   else
      graph = ACN.new('@')
   end
   local upvalues = {istype=env.istype, graph=graph}

   local optperrule = {}
   for ridx, rule in ipairs(rules) do
      if rule.default ~= nil or rule.defaulta or rule.defaultf then
         optperrule[ridx] = 3 -- here, nil or not here
      elseif rule.opt then
         optperrule[ridx] = 3 -- here, nil or not here
      else
         optperrule[ridx] = 1 -- here
      end
   end

   local optperrulestride = {}
   local nvariant = 1
   for ridx=#rules,1,-1 do
      optperrulestride[ridx] = nvariant
      nvariant = nvariant * optperrule[ridx]
   end

   -- note: we keep the original rules (id) for all path variants
   -- hence, the mask.
   for variant=nvariant,1,-1 do
      local r = variant
      local rulemask = {} -- 1/2/3 means present [ordered]/not present [ordered]/ nil [named or ordered]
      for ridx=1,#rules do
         table.insert(rulemask, math.floor((r-1)/optperrulestride[ridx]) + 1)
         r = (r-1) % optperrulestride[ridx] + 1
      end
      rulemask = table.concat(rulemask)

      if not rules.noordered then
         graph:addpath(rules, rulemask, 'O')
      end

      if not rules.nonamed then
         if rules[1] and rules[1].name == 'self' then
            graph:addpath(rules, rulemask, 'M')
         else
            graph:addpath(rules, rulemask, 'N')
         end
      end
   end

   local code = graph:generate(upvalues)

   return code, upvalues
end

local function argcheck(rules)

   -- basic checks
   assert(not (rules.noordered and rules.nonamed), 'rules must be at least ordered or named')
   assert(rules.help == nil or type(rules.help) == 'string', 'rules help must be a string or nil')
   assert(rules.doc == nil or type(rules.doc) == 'string', 'rules doc must be a string or nil')
   assert(rules.chain == nil or type(rules.chain) == 'function', 'rules chain must be a function or nil')
   assert(rules.overload == nil or type(rules.overload) == 'function', 'rules overload must be a function or nil')
   assert(not (rules.chain and rules.overload), 'rules must have either overload [or chain (deprecated)]')
   assert(not (rules.doc and rules.help), 'choose between doc or help, not both')
   for _, rule in ipairs(rules) do
      assert(rule.name, 'rule must have a name field')
      assert(rule.type == nil or type(rule.type) == 'string', 'rule type must be a string or nil')
      assert(rule.help == nil or type(rule.help) == 'string', 'rule help must be a string or nil')
      assert(rule.doc == nil or type(rule.doc) == 'string', 'rule doc must be a string or nil')
      assert(rule.check == nil or type(rule.check) == 'function', 'rule check must be a function or nil')
      assert(rule.defaulta == nil or type(rule.defaulta) == 'string', 'rule defaulta must be a string or nil')
      assert(rule.defaultf == nil or type(rule.defaultf) == 'function', 'rule defaultf must be a function or nil')
   end
   if rules[1] and rules[1].name == 'self' then
      local rule = rules[1]
      assert(
            not rule.opt
            and not rule.default
            and not rule.defaulta
            and not rule.defaultf,
         'self cannot be optional, nor having a default value!')
   end

   -- dump doc if any
   if rules.doc or rules.help then
      doc(usage(true, rules, true))
   end

   local code, upvalues = generaterules(rules)
   if rules.debug then
      print(code)
   end
   local func, err = loadstring(code, 'argcheck')
   if not func then
      error(string.format('could not generate argument checker: %s', err))
   end
   func = func()

   for upvaluename, upvalue in pairs(upvalues) do
      setupvalue(func, upvaluename, upvalue)
   end

   if rules.debug then
      return func, upvalues.graph:print()
   else
      return func
   end
end

env.argcheck = argcheck

return argcheck
