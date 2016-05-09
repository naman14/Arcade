local cwrap = {}

cwrap.types = require 'cwrap.types'
cwrap.CInterface = require 'cwrap.cinterface'
cwrap.CInterface.argtypes = cwrap.types

return cwrap
