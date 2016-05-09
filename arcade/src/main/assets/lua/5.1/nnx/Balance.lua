local Balance, parent = torch.class('nn.Balance', 'nn.Module')
------------------------------------------------------------------------
--[[ Balance ]]--
-- Constrains the distribution of a preceding SoftMax to have equal 
-- probability of category over examples. So each category has a 
-- mean probability of 1/nCategory.
------------------------------------------------------------------------

function Balance:__init(nBatch)
   parent.__init(self)
   self.nBatch = nBatch or 10
   self.inputCache = torch.Tensor()
   self.prob = torch.Tensor()
   self.sum = torch.Tensor()
   self.batchSize = 0
   self.startIdx = 1
   self.train = true
end

function Balance:updateOutput(input)
   assert(input:dim() == 2, "Only works with 2D inputs (batches)")
   if self.batchSize ~= input:size(1) then
      self.inputCache:resize(input:size(1)*self.nBatch, input:size(2)):zero()
      self.batchSize = input:size(1)
      self.startIdx = 1
   end
   
   self.output:resizeAs(input):copy(input)
   if not self.train then
      return self.output
   end
   -- keep track of previous batches of P(Y|X)
   self.inputCache:narrow(1, self.startIdx, input:size(1)):copy(input)
   
   -- P(X) is uniform for all X, i.e. P(X) = 1/c where c is a constant
   -- P(Y) = sum_x( P(Y|X)*P(X) )
   self.prob:sum(self.inputCache, 1):div(self.prob:sum())
   -- P(X|Y) = P(Y|X)*P(X)/P(Y)
   self.output:cdiv(self.prob:resize(1,input:size(2)):expandAs(input))--:div(input:size(2))
   -- P(Z|X) = P(X|Y)*sum_y( P(X|Y) ) where P(Z) = 1/d where d is a constant
   self.sum:sum(self.output, 2)
   self.output:cdiv(self.sum:resize(input:size(1),1):expandAs(self.output))
   
   self.startIdx = self.startIdx + self.batchSize
   if self.startIdx > self.inputCache:size(1) then
      self.startIdx = 1
   end

   return self.output
end

function Balance:updateGradInput(input, gradOutput)
   self.gradInput:resizeAs(gradOutput)
   self.gradInput:copy(gradOutput)
   self.gradInput:cdiv(self.sum:resize(input:size(1),1):expandAs(self.output))
   self.gradInput:cdiv(self.prob:resize(1,input:size(2)):expandAs(input))
   return self.gradInput
end
