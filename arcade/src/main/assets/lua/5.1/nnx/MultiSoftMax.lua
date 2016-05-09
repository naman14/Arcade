------------------------------------------------------------------------
--[[ MultiSoftMax ]]--
-- Takes 2D or 3D input and performs a softmax over the last dimension.
------------------------------------------------------------------------
local MultiSoftMax, parent = torch.class('nn.MultiSoftMax', 'nn.Module')

function MultiSoftMax.__init(self)
   parent.__init(self)
   self._input = torch.Tensor()
   self._output = torch.Tensor()
   self._gradInput = torch.Tensor()
   self._gradOutput = torch.Tensor()
end

function MultiSoftMax:updateOutput(input)
   if input:dim() == 2 then
      return input.THNN.SoftMax_updateOutput(input:cdata(), self.output:cdata())
   end
   if input:dim() ~= 3 then
      error"Only supports 2D or 3D inputs"
   end
   self._input:view(input, input:size(1)*input:size(2), input:size(3))
   local output = self.output
   self.output = self._output
   input.THNN.SoftMax_updateOutput(self._input:cdata(), self.output:cdata())
   output:viewAs(self.output, input)
   self.output = output
   return self.output
end

function MultiSoftMax:updateGradInput(input, gradOutput)
   if input:dim() == 2 then
      return input.THNN.SoftMax_updateGradInput(input:cdata(), gradOutput:cdata(),
                                                self.gradInput:cdata(), self.output:cdata())
   end
   self._gradOutput:view(gradOutput, input:size(1)*input:size(2), input:size(3))
   local gradInput = self.gradInput
   self.gradInput = self._gradInput
   local output = self.output
   self.output = self._output
   input.THNN.SoftMax_updateGradInput(self._input:cdata(), self._gradOutput:cdata(),
                                      self.gradInput:cdata(), self.output:cdata())
   self.gradInput = gradInput:viewAs(self.gradInput, input)
   self.output = output
   return self.gradInput
end
