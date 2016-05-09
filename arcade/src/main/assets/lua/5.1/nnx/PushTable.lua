local PushTable, parent = torch.class("nn.PushTable", "nn.Module")

function PushTable:__init(index)
   self._index = index
   self._pulls = {}
   self.output = {}
   self._gradInput = torch.Tensor()
   self.gradInput = {}
   self._forward = false
end

function PushTable:pull(index)
   local pull = nn.PullTable(self, index)
   table.insert(self._pulls, pull)
   return pull
end

function PushTable:updateOutput(inputTable)
   for i, input in ipairs(inputTable) do
      if i < self._index then
         self.output[i] = input
      elseif i > self._index then
         self.output[i-1] = input
      end
   end
   
   local input = inputTable[self._index]
   for i,pull in ipairs(self._pulls) do
      pull:_updateOutput(input)
   end
   
   self._forward = true
   return self.output
end

function PushTable:_updateGradInput(gradOutput)
   if self._forward then
      if torch.type(self.gradInput) ~= torch.type(gradOutput) then
         self._gradInput = gradOutput.new()
      end
      self._gradInput:resizeAs(gradOutput)
      self._gradInput:copy(gradOutput)
   else
      self._gradInput:add(gradOutput)
   end
   self._forward = false
end

function PushTable:updateGradInput(inputTable, gradOutputTable)
   for i, gradOutput in ipairs(gradOutputTable) do
      if i < self._index then
         self.gradInput[i] = gradOutput
      elseif i > self._index then
         self.gradInput[i+1] = gradOutput
      end
   end
   self.gradInput[self._index] = self._gradInput
   assert(#inputTable == #self.gradInput, "tables size mismatch")
   return self.gradInput
end


function PushTable:type(type, tensorCache)
   assert(type, 'PullTable: must provide a type to convert to')

   tensorCache = tensorCache or {}

   -- find all tensors and convert them
   for key,param in pairs(self) do
       if(key ~= "_pulls") then
             self[key] = nn.utils.recursiveType(param, type, tensorCache)
        end
   end
   return self
end


