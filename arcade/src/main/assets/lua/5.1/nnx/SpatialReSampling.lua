local SpatialReSampling, parent = torch.class('nn.SpatialReSampling', 'nn.Module')

local help_desc =
[[Applies a 2D re-sampling over an input image composed of
several input planes. The input tensor in forward(input) is 
expected to be a 3D or 4D tensor ([batchSize x nInputPlane x width x height). 
The number of output planes will be the same as the nb of input
planes.

The re-sampling is done using bilinear interpolation. For a
simple nearest-neihbor upsampling, use nn.SpatialUpSampling(),
and for a simple average-based down-sampling, use 
nn.SpatialDownSampling().

If the input image is a 3D tensor nInputPlane x height x width,
the output image size will be nInputPlane x oheight x owidth where
owidth and oheight are given to the constructor.

Instead of owidth & oheight, one can provide rwidth & rheight, 
such that owidth = iwidth*rwidth & oheight = iheight*rheight. ]]

function SpatialReSampling:__init(...)
   parent.__init(self)
   xlua.unpack_class(
      self, {...}, 'nn.SpatialReSampling', help_desc,
      {arg='rwidth', type='number', help='ratio: owidth/iwidth'},
      {arg='rheight', type='number', help='ratio: oheight/iheight'},
      {arg='owidth', type='number', help='output width'},
      {arg='oheight', type='number', help='output height'}
   )
end

function SpatialReSampling:updateOutput(input)
   assert(input:dim() == 3 or input:dim() == 4,
          'input to SpatialReSampling must be 3D or 4D, received: [' ..
          table.concat(input:size():totable(), ', ') .. ']')
   local hDim, wDim = 2, 3
   if input:dim() == 4 then
      hDim, wDim = 3, 4
   end
   self.oheight = self.oheight or self.rheight*input:size(hDim)
   self.owidth = self.owidth or self.rwidth*input:size(wDim)
   input.nn.SpatialReSampling_updateOutput(self, input)
   return self.output
end

function SpatialReSampling:updateGradInput(input, gradOutput)
   input.nn.SpatialReSampling_updateGradInput(self, input, gradOutput)
   return self.gradInput
end
