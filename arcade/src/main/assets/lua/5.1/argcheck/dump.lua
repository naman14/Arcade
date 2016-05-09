local doc = require 'argcheck.doc'

local ffi = require 'ffi'

doc.__noop = ffi.new('int*')
ffi.gc(doc.__noop,
       function()
          print(doc.stop())
       end)

doc.record()
