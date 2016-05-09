------------------------------------------------------------------------
--[[ TreeNLLCriterion ]]--
-- Negative Log Likelihood for SoftMaxTrees.
-- Used for maximizing the likelihood of SoftMaxTree outputs.
-- SoftMaxTree outputs a column tensor representing the log likelihood
-- of each target in the batch. Thus SoftMaxTree requires the targets.
-- So this Criterion only computes the negative of those outputs, as 
-- well as its corresponding gradients.
------------------------------------------------------------------------
local TreeNLLCriterion, parent = torch.class("nn.TreeNLLCriterion", "nn.Criterion")

function TreeNLLCriterion:__init()
   self._module = nn.Mean() 
   parent.__init(self)
   self._output_grad = torch.Tensor{-1}
end

function TreeNLLCriterion:updateOutput(input, target)
   return -self._module:forward(input)[1]
end

function TreeNLLCriterion:updateGradInput(input, target)
   return self._module:backward(input, self._output_grad)
end
