require 'nn'


--Based on: http://arxiv.org/pdf/1412.6830v1.pdf
--If input dimension is larger than 1, a reshape is needed after usage.
--Usage:
------------------------------------
--	model:add(LA(4, 3 * 32 * 32))
--  model:add(nn.Reshape(3,32,32))
------------------------------------


function LA(s, inputSize)
	local module = nn.Sequential()
	local maxmodules = {}
	for i = 1,s do
		maxmodules[i] = nn.Sequential()
		maxmodules[i]:add(nn.MulConstant(-1.0))		
		maxmodules[i]:add(nn.Add(inputSize,true))
		maxmodules[i]:add(nn.ReLU())
		maxmodules[i]:add(nn.CMul(inputSize))
	end
	maxmodules[s+1] = nn.Sequential()
	maxmodules[s+1]:add(nn.ReLU())

	local catmodule = nn.ConcatTable()
	print('number of modules is: '.. #maxmodules)
	for i=1,#maxmodules do
		catmodule:add(maxmodules[i])
	end
	
	module:add(catmodule)
    

	module:add(nn.JoinTable(1))
	module:add(nn.Reshape(s + 1,inputSize))

	module:add(nn.Sum(1))


	return module
end

