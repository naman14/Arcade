----------------------------------------------------------------------
--
-- Copyright (c) 2011 Clement Farabet, Marco Scoffier, 
--                    Koray Kavukcuoglu, Benoit Corda
--
-- 
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- 
----------------------------------------------------------------------

require 'torch'
require 'xlua'
require 'nn'

-- create global nnx table:
nnx = {}

-- c lib:
require 'libnnx'

-- for testing:
require('nnx.test-all')
require('nnx.test-omp')

-- tools:
require('nnx.Probe')
require('nnx.Tic')
require('nnx.Toc')

-- spatial (images) operators:
require('nnx.SpatialLinear')
require('nnx.SpatialClassifier')
require('nnx.SpatialNormalization')
require('nnx.SpatialPadding')
require('nnx.SpatialReSamplingEx')
require('nnx.SpatialUpSampling')
require('nnx.SpatialDownSampling')
require('nnx.SpatialReSampling')
require('nnx.SpatialRecursiveFovea')
require('nnx.SpatialFovea')
require('nnx.SpatialPyramid')
require('nnx.SpatialGraph')
require('nnx.SpatialMatching')
require('nnx.SpatialRadialMatching')
require('nnx.SpatialMaxSampling')
require('nnx.SpatialColorTransform')

-- other modules
require('nnx.FunctionWrapper')

-- misc
require('nnx.SaturatedLU')
require('nnx.Minus')
require('nnx.SoftMaxTree')
require('nnx.MultiSoftMax')
require('nnx.Balance')
require('nnx.PushTable')
require('nnx.PullTable')
require('nnx.ZeroGrad')

-- criterions:
require('nnx.SuperCriterion')
require('nnx.DistNLLCriterion')
require('nnx.DistMarginCriterion')
require('nnx.TreeNLLCriterion')
require('nnx.CTCCriterion')

-- datasets:
require('nnx.DataSet')
require('nnx.DataList')
require('nnx.DataSetLabelMe')
require('nnx.DataSetSamplingPascal')
