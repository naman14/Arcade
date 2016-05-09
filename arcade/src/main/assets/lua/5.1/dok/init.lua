dok = {}

require 'dok.inline'

local ok,sd = pcall(require, 'sundown')
if ok then
    dok.markdown2html = sd.render
else
    dok.markdown2html = function() return '<p> Error: Sundown could not be loaded </p>' end
end
