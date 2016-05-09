local PullTable, parent = torch.class("nn.PullTable", "nn.Module")

function PullTable:__init(push, index)
   self._push = push
   self._index = index
   self.output = {}
   self.gradInput = {}
end

function PullTable:_updateOutput(output)
   self._output = output
end

function PullTable:updateOutput(inputTable)
   if torch.type(inputTable) == 'table' then
      for i, input in ipairs(inputTable) do
         if i < self._index then
            self.output[i] = input
         else
            self.output[i+1] = input
         end
      end
      self.output[self._index] = self._output
   else
      if self._index == 1 then
         self.output[2] = inputTable
         self.output[1] = self._output
      else
         assert(self._index == 2, "table index out of range")
         self.output[1] = inputTable
         self.output[2] = self._output
      end
   end
   return self.output
end

function PullTable:updateGradInput(inputTable, gradOutputTable)
   self._push:_updateGradInput(gradOutputTable[self._index])
   
   if torch.type(inputTable) == 'table' then
      if torch.type(self.gradInput) ~= 'table' then
         self.gradInput = {}
      end
      for i, gradOutput in ipairs(gradOutputTable) do
         if i < self._index then
            self.gradInput[i] = gradOutput
         elseif i > self._index then
            self.gradInput[i-1] = gradOutput
         end
      end
      assert(#inputTable == #self.gradInput, "tables size mismatch")   
   else
      if self._index == 1 then
         self.gradInput = gradOutputTable[2]
      else
         self.gradInput = gradOutputTable[1]
      end
   end
   return self.gradInput
end


function PullTable:type(type, tensorCache)
   assert(type, 'PullTable: must provide a type to convert to')

   tensorCache = tensorCache or {}

   -- find all tensors and convert them
   for key,param in pairs(self) do
       if(key ~= "_push") then
             self[key] = nn.utils.recursiveType(param, type, tensorCache)
   	     end
   end

   return self
end

