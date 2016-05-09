local SoftMaxTree, parent = torch.class('nn.SoftMaxTree', 'nn.Module')
------------------------------------------------------------------------
--[[ SoftMaxTree ]]--
-- Computes the log of a product of softmaxes in a path
-- Returns an output tensor of size 1D
-- Only works with a tree (one parent per child)
------------------------------------------------------------------------

function SoftMaxTree:__init(inputSize, hierarchy, rootId, accUpdate, static, verbose)
   parent.__init(self)
   self.rootId = rootId or 1
   self.inputSize = inputSize
   self.accUpdate = accUpdate
   assert(type(hierarchy) == 'table', "Expecting table at arg 2")
   -- get the total amount of children (non-root nodes)
   local nChildNode = 0
   local nParentNode = 0
   local maxNodeId = -999999999
   local minNodeId = 999999999
   local maxParentId = -999999999
   local maxChildId = -999999999
   local maxFamily = -999999999
   local parentIds = {}
   for parentId, children in pairs(hierarchy) do
      assert(children:dim() == 1, "Expecting table of 1D tensors at arg 2")
      nChildNode = nChildNode + children:size(1)
      nParentNode = nParentNode + 1
      maxParentId = math.max(parentId, maxParentId)
      maxFamily = math.max(maxFamily, children:size(1))
      local maxChildrenId = children:max()
      maxChildId = math.max(maxChildrenId, maxChildId)
      maxNodeId = math.max(parentId, maxNodeId, maxChildrenId)
      minNodeId = math.min(parentId, minNodeId, children:min())
      table.insert(parentIds, parentId)
   end
   if minNodeId < 0 then
      error("nodeIds must must be positive: "..minNodeId, 2)
   end
   if verbose then
      print("Hierachy has :")
      print(nParentNode.." parent nodes")
      print(nChildNode.." child nodes")
      print((nChildNode - nParentNode).." leaf nodes")
      print("node index will contain "..maxNodeId.." slots")
      if maxNodeId ~= (nChildNode + 1) then
         print("Warning: Hierarchy has more nodes than Ids")
         print("Consider making your nodeIds a contiguous sequence ")
         print("in order to waste less memory on indexes.")
      end
   end
   
   self.nChildNode = nChildNode
   self.nParentNode = nParentNode
   self.minNodeId = minNodeId
   self.maxNodeId = maxNodeId
   self.maxParentId = maxParentId
   self.maxChildId = maxChildId
   self.maxFamily = maxFamily
   
   -- initialize weights and biases
   self.weight = torch.Tensor(self.nChildNode, self.inputSize)
   self.bias = torch.Tensor(self.nChildNode)
   if not self.accUpdate then
      self.gradWeight = torch.Tensor(self.nChildNode, self.inputSize)
      self.gradBias = torch.Tensor(self.nChildNode)
   end
   
   -- contains all childIds
   self.childIds = torch.IntTensor(self.nChildNode)
   -- contains all parentIds
   self.parentIds = torch.IntTensor(parentIds)
   
   -- index of children by parentId
   self.parentChildren = torch.IntTensor(self.maxParentId, 2):fill(-1)
   local start = 1
   for parentId, children in pairs(hierarchy) do
      local node = self.parentChildren:select(1, parentId)
      node[1] = start
      local nChildren = children:size(1)
      node[2] = nChildren
      self.childIds:narrow(1, start, nChildren):copy(children)
      start = start + nChildren
   end
   
   -- index of parent by childId
   self.childParent = torch.IntTensor(self.maxChildId, 2):fill(-1)
   for parentIdx=1,self.parentIds:size(1) do
      local parentId = self.parentIds[parentIdx]
      local node = self.parentChildren:select(1, parentId)
      local start = node[1]
      local nChildren = node[2]
      local children = self.childIds:narrow(1, start, nChildren)
      for childIdx=1,children:size(1) do
         local childId = children[childIdx]
         local child = self.childParent:select(1, childId)
         child[1] = parentId
         child[2] = childIdx
      end
   end
   
   -- used to allocate buffers 
   -- max nChildren in family path
   local maxFamilyPath = -999999999
   -- max number of parents
   local maxDept = -999999999
   local treeSizes = {[rootId] = self.parentChildren[rootId][2]}
   local pathSizes = {[rootId] = 1}
   local function getSize(nodeId) 
      local treeSize, pathSize = treeSizes[nodeId], pathSizes[nodeId]
      if not treeSize then
         local parentId = self.childParent[nodeId][1]
         local nChildren = self.parentChildren[nodeId][2]
         treeSize, pathSize = getSize(parentId) 
         treeSize = treeSize + nChildren
         pathSize = pathSize + 1
         treeSizes[nodeId] = treeSize
         pathSizes[nodeId] = pathSize
      end
      return treeSize, pathSize
   end
   for parentIdx=1,self.parentIds:size(1) do
      local parentId = self.parentIds[parentIdx]
      local treeSize, pathSize = getSize(parentId)
      maxFamilyPath = math.max(treeSize, maxFamilyPath)
      maxDept = math.max(pathSize, maxDept)
   end
   self.maxFamilyPath = maxFamilyPath
   self.maxDept = maxDept
   
   -- stores the parentIds of nodes that have been accGradParameters
   self.updates = {}
   
   -- used internally to store intermediate outputs or gradOutputs
   self._nodeBuffer = torch.Tensor()
   self._multiBuffer = torch.Tensor()
   
   self.batchSize = 0
   
   self._gradInput = torch.Tensor()
   self._gradTarget = torch.IntTensor() -- dummy
   self.gradInput = {self._gradInput, self._gradTarget}
   self.static = (static == nil) and true or static
   
   self:reset()
end

function SoftMaxTree:reset(stdv)
   if stdv then
      stdv = stdv * math.sqrt(3)
   else
      stdv = 1/math.sqrt(self.nChildNode*self.inputSize)
   end
   self.weight:uniform(-stdv, stdv)
   self.bias:uniform(-stdv, stdv)
end

function SoftMaxTree:updateOutput(inputTable)
   local input, target = unpack(inputTable)
   -- buffers:
   if self.batchSize ~= input:size(1) then
      self._nodeBuffer:resize(self.maxFamily)
      self._multiBuffer:resize(input:size(1)*self.maxFamilyPath)
      self.batchSize = input:size(1)
      -- so that it works within nn.ConcatTable :
      self._gradTarget:resizeAs(target):zero() 
      if self._nodeUpdateHost then
         self._nodeUpdateHost:resize(input:size(1),self.maxDept)
         self._nodeUpdateCuda:resize(input:size(1),self.maxDept)
      end
   end
   return input.nn.SoftMaxTree_updateOutput(self, input, target)
end

function SoftMaxTree:updateGradInput(inputTable, gradOutput)
   local input, target = unpack(inputTable)
   if not gradOutput:isContiguous() and torch.type(gradOutput) == 'torch.CudaTensor' then
      self._gradOutput = self._gradOutput or gradOutput.new()
      self._gradOutput:resizeAs(gradOutput):copy(gradOutput)
      gradOutput = self._gradOutput
   end
   if self.gradInput then
      input.nn.SoftMaxTree_updateGradInput(self, input, gradOutput, target)
   end
   return self.gradInput
end

function SoftMaxTree:accGradParameters(inputTable, gradOutput, scale)
   local input, target = unpack(inputTable)
   gradOutput = self._gradOutput or gradOutput
   scale = scale or 1
   input.nn.SoftMaxTree_accGradParameters(self, input, gradOutput, target, scale)
end

-- when static is true, return parameters with static keys
-- i.e. keys that don't change from batch to batch
function SoftMaxTree:parameters()
   local static = self.static
   local params, grads = {}, {}
   local updated = false
   for parentId, scale in pairs(self.updates) do
      local node = self.parentChildren:select(1, parentId)
      local parentIdx = node[1]
      local nChildren = node[2]
      if static then -- for use with pairs
         params[parentId] = self.weight:narrow(1, parentIdx, nChildren)
         local biasId = parentId+self.maxParentId
         params[biasId] = self.bias:narrow(1, parentIdx, nChildren)
         if not self.accUpdate then
            grads[parentId] = self.gradWeight:narrow(1, parentIdx, nChildren)
            grads[biasId] = self.gradBias:narrow(1, parentIdx, nChildren)
         end
      else -- for use with ipairs
         table.insert(params, self.weight:narrow(1, parentIdx, nChildren))
         table.insert(params, self.bias:narrow(1, parentIdx, nChildren))
         if not self.accUpdate then
            table.insert(grads, self.gradWeight:narrow(1, parentIdx, nChildren))
            table.insert(grads, self.gradBias:narrow(1, parentIdx, nChildren))
         end
      end
      updated = true
   end
   if not updated then
      if static then -- consistent with static = true
         for i=1,self.parentIds:size(1) do
            local parentId = self.parentIds[i]
            local node = self.parentChildren:select(1, parentId)
            local parentIdx = node[1]
            local nChildren = node[2]
            params[parentId] = self.weight:narrow(1, parentIdx, nChildren)
            local biasId = parentId+self.maxParentId
            params[biasId] = self.bias:narrow(1, parentIdx, nChildren)
            if not self.accUpdate then
               grads[parentId] = self.gradWeight:narrow(1, parentIdx, nChildren)
               grads[biasId] = self.gradBias:narrow(1, parentIdx, nChildren)
            end
         end
      else
         return {self.weight, self.bias}, {self.gradWeight, self.gradBias}
      end
   end
   return params, grads, {}, self.nChildNode*2
end

function SoftMaxTree:updateParameters(learningRate)
   assert(not self.accUpdate)
   local params, gradParams = self:parameters()
   if params then
      for k,param in pairs(params) do
         param:add(-learningRate, gradParams[k])
      end
   end
end

function SoftMaxTree:getNodeParameters(parentId)
   local node = self.parentChildren:select(1,parentId)
   local start = node[1]
   local nChildren = node[2]
   local weight = self.weight:narrow(1, start, nChildren)
   local bias = self.bias:narrow(1, start, nChildren)
   if not self.accUpdate then
      local gradWeight = self.gradWeight:narrow(1, start, nChildren)
      local gradBias = self.gradBias:narrow(1, start, nChildren)
      return {weight, bias}, {gradWeight, gradBias}
   end
   return {weight, bias}
end

function SoftMaxTree:zeroGradParameters()
   local _,gradParams = self:parameters()
   for k,gradParam in pairs(gradParams) do
      gradParam:zero()
   end
   -- loop is used instead of 'self.updates = {}'
   -- to handle the case when updates are shared
   for k,v in pairs(self.updates) do
      self.updates[k] = nil
   end
end

function SoftMaxTree:type(type, typecache)
   if type == torch.type(self.weight) then
      return self
   end
   
   local hierarchy = self.hierarchy
   self.hierarchy = nil
   self._nodeUpdateHost = nil
   self._nodeUpdateCuda = nil
   self._paramUpdateHost = nil
   self._paramUpdateCuda = nil
   local parentChildren = self.parentChildren
   self.parentChildren = nil
   self.parentChildrenCuda = nil
   local childParent = self.childParent
   self.childParent = nil
   self.childParentCuda = nil
   local _gradTarget = self._gradTarget
   self._gradTarget = nil
   local childIds = self.childIds
   self.childIds = nil
   local parentIds = self.parentIds
   self.parentIds = nil
   self._gradOutput = nil
   
   parent.type(self, type, typecache)
   
   self.hierarchy = hierarchy
   self.parentChildren = parentChildren
   self.childParent = childParent
   self._gradTarget = _gradTarget
   self.childIds = childIds
   self.parentIds = parentIds
   
   if (type == 'torch.CudaTensor') then
      -- cunnx needs this for filling self.updates
      self._nodeUpdateHost = torch.IntTensor()
      self._nodeUpdateCuda = torch.CudaIntTensor()
      self._paramUpdateHost = torch.IntTensor()
      self._paramUpdateCuda = torch.CudaTensor()
      self.parentChildrenCuda = self.parentChildren:type(type)
      self.childParentCuda = self.childParent:type(type)
      self._gradTarget = self._gradTarget:type(type)
   elseif self._nodeUpdateHost then
      self._nodeUpdateHost = nil
      self._nodeUpdateCuda = nil
      self.parentChildren = self.parentChildren:type('torch.IntTensor')
      self.childParent = self.childParent:type('torch.IntTensor')
      self._gradTarget = self._gradTarget:type('torch.IntTensor')
   end
   self.gradInput = {self._gradInput, self._gradTarget} 
   self.batchSize = 0 --so that buffers are resized
   return self
end

function SoftMaxTree:maxNorm(maxNorm)
   local params = self:parameters()
   if params then
      for k,param in pairs(params) do
         if param:dim() == 2 and maxNorm then
            param:renorm(2,1,maxNorm)
         end
      end
   end
end

-- we do not need to accumulate parameters when sharing
SoftMaxTree.sharedAccUpdateGradParameters = SoftMaxTree.accUpdateGradParameters
