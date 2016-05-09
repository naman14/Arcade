--------------------------------------------------------------------------------
-- Profiler: a simple class to help profiling code
--------------------------------------------------------------------------------
local Profiler = {}

function xlua.Profiler(mode,verbose)
   local self = {}
   self.events = {}
   self.list = {}
   self.off = (mode == 'off') or false
   self.verbose = verbose or false
   for k,v in pairs(Profiler) do
      self[k] = v
   end
   return self
end

function Profiler:start(name, fps)
   if self.events[name] then
      -- update
      self.events[name].cpu = os.clock()
      self.events[name].real = sys.clock()
   else
      -- create
      self.events[name] = {cpu=os.clock(), real=sys.clock(), name=name}
      self.list[#self.list+1] = self.events[name]
   end
   if fps and fps == 'fps' then
      self.events[name].fps = true
   end
   if self.verbose then io.write('<' .. name .. '>') io.flush() end
end

function Profiler:setColor(name, color)
   if self.events[name] then
      -- update
      self.events[name].color = color
   else
      error('# ERROR: There is no such profiler - '.. name..', create it first')
   end
end


function Profiler:cpu(name,divider)
   local delta = os.clock() - self.events[name].cpu
   if divider then delta = delta / divider end
   self.events[name].cpud = delta
   return delta
end

function Profiler:real(name,divider)
   local delta = sys.clock() - self.events[name].real
   if divider then delta = delta / divider end
   self.events[name].reald = delta
   return delta
end

function Profiler:lap(name,divider)
   local r = self:real(name,divider)
   local c = self:cpu(name,divider)
   if self.verbose then io.write('\r') self:print(name) end
   return r,c
end

function Profiler:format(name)
   return string.format('$ real | cpu: %f | %f <%s>',
                        self.events[name].reald or -1, self.events[name].cpud or -1, name)
end

function Profiler:print(name)
   if not self.off then
      print(self:format(name))
   end
end

function Profiler:formatAll()
   local str = '$ profiler report:'
   for i = 1,#self.list do
      if self.list[i].fps then
         str = str .. '\n' .. string.format('$ real %f | cpu %f <%s> = %f fps',
                                            self.list[i].reald or -1,
                                            self.list[i].cpud or -1,
                                            self.list[i].name,
                                            1/self.list[i].reald)
      else
         str = str .. '\n' .. string.format('$ real %f | cpu %f <%s>',
                                            self.list[i].reald or -1,
                                            self.list[i].cpud or -1,
                                            self.list[i].name)
      end
   end
   return str
end

function Profiler:printAll()
   if not self.off then
      print(self:formatAll())
   end
end

function Profiler:displayAll(args)
   -- args
   local x = args.x or 0
   local y = args.y or 0
   local zoom = args.zoom or 1
   local painter = args.painter or args.win
   local font = args.font or 24*zoom
   if not painter then error('# ERROR: Profiler.displayAll() needs a painter') end

   painter:setfont(qt.QFont{serif=false,italic=false,size=font})
   if not self.off then
      for i = 1,#self.list do
         painter:setcolor(self.list[i].color or "black")
         local str
         if self.list[i].fps then
            str = string.format('$ real %f | cpu %f <%s> = %f fps',
                                self.list[i].reald or -1,
                                self.list[i].cpud or -1,
                                self.list[i].name,
                                1/self.list[i].reald)
         else
            str = string.format('$ real %f | cpu %f <%s>',
                                self.list[i].reald or -1,
                                self.list[i].cpud or -1,
                                self.list[i].name)
         end
         -- disp line:
         painter:moveto(x,y); y = y + font*1.5
         painter:show(str)
      end
   end
end
