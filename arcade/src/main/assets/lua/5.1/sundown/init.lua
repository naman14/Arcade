local sundown = require 'sundown.env'
local html = require 'sundown.html'
local ascii = require 'sundown.ascii'

sundown.render = html.render
sundown.renderHTML = html.render
sundown.renderASCII = ascii.render

return sundown
