require 'torch'

local ffiOk = false
local graphvizOk = false
local cgraphOk = false
local ffi
local graphviz
local cgraph

ffiOk, ffi = pcall(require, 'ffi')
if ffiOk then
   ffi.cdef[[
   typedef struct FILE FILE;

   typedef struct Agraph_s Agraph_t;
   typedef struct Agnode_s Agnode_t;

   extern Agraph_t *agmemread(const char *cp);
   extern char *agget(void *obj, char *name);
   extern int agclose(Agraph_t * g);
   extern Agnode_t *agfstnode(Agraph_t * g);
   extern Agnode_t *agnxtnode(Agraph_t * g, Agnode_t * n);
   extern Agnode_t *aglstnode(Agraph_t * g);
   extern Agnode_t *agprvnode(Agraph_t * g, Agnode_t * n);

   typedef struct Agraph_s graph_t;
   typedef struct GVJ_s GVJ_t;
   typedef struct GVG_s GVG_t;
   typedef struct GVC_s GVC_t;
   extern GVC_t *gvContext(void);
   extern int gvLayout(GVC_t *context, graph_t *g, const char *engine);
   extern int gvRender(GVC_t *context, graph_t *g, const char *format, FILE *out);
   extern int gvFreeLayout(GVC_t *context, graph_t *g);
   extern int gvFreeContext(GVC_t *context);

   FILE * fopen ( const char * filename, const char * mode );
   int fclose ( FILE * stream );
   ]]
   graphvizOk, graphviz = pcall(function() return ffi.load('libgvc', true) end)
   if not graphvizOk then
      graphvizOk, graphviz = pcall(function() return ffi.load('libgvc.so.6', true) end)
   end

   cgraphOk, cgraph = pcall(function() return ffi.load('libcgraph', true) end)
   if not cgraphOk then
      cgraphOk, cgraph = pcall(function() return ffi.load('libcgraph.so.6', true) end)
   end
else
   graphvizOk = false
   cgraphOk = false
end

local unpack = unpack or table.unpack -- Lua52 compatibility
local NULL = (ffiOk and (not jit)) and ffi.C.NULL or nil -- LuaJIT compatibility

-- Retrieve attribute data from a graphviz object.
local function getAttribute(obj, name)
   local res = cgraph.agget(obj, ffi.cast("char*", name))
   assert(res ~= ffi.cast("char*", nil), 'could not get attr ' .. name)
   local out = ffi.string(res)
   return out
end
-- Iterate through nodes of a graphviz graph.
local function nodeIterator(graph)
   local node = cgraph.agfstnode(graph)
   local nextNode
   return function()
      if node == NULL then return end
      if node == cgraph.aglstnode(graph) then nextNode = NULL end
      nextNode = cgraph.agnxtnode(graph, node)
      local result = node
      node = nextNode
      return result
   end
end
-- Convert a string of comma-separated numbers to actual numbers.
local function extractNumbers(n, attr)
   local res = {}
   for number in string.gmatch(attr, "[^%,]+") do
      table.insert(res, tonumber(number))
   end
   assert(#res == n, "attribute is not of expected form")
   return unpack(res)
end
-- Transform from graphviz coordinates to unit square.
local function getRelativePosition(node, bbox)
   local x0, y0, w, h = unpack(bbox)
   local x, y = extractNumbers(2, getAttribute(node, 'pos'))
   local xt = (x - x0) / w
   local yt = (y - y0) / h
   assert(xt >= 0 and xt <= 1, "bad x coordinate")
   assert(yt >= 0 and yt <= 1, "bad y coordinate")
   return xt, yt
end
-- Retrieve a node's ID based on its label string.
local function getID(node)
   local label = getAttribute(node, 'label')
   local res = {string.find(label, "^Node(%d+)")} or {string.find(label, "%((%d+)%)\\n")}
   local id = res[3]
   assert(id ~= nil, "could not get ID from node label : <" .. tostring(label) .. ">")
   return tonumber(id)
end

--[[ Lay out a graph and return the positions of the nodes.

Args:
* `g` - graph to lay out.
* `algorithm` - name of the graphviz algorithm to use. (default: "dot")

Returns:
* `torch.Tensor(n, 2)` containing the resulting positions of the nodes.
where `n` is the number of nodes in the graph.

Coordinates are in the interval [0, 1].

]]
function graph.graphvizLayout(g, algorithm)
   if not graphvizOk or not cgraphOk then
      error("graphviz library could not be loaded.")
   end
   local nNodes = #g.nodes
   local context = graphviz.gvContext()
   local graphvizGraph = cgraph.agmemread(g:todot())
   local algorithm = algorithm or "dot"
   assert(0 == graphviz.gvLayout(context, graphvizGraph, algorithm),
          "graphviz layout failed")
   assert(0 == graphviz.gvRender(context, graphvizGraph, algorithm, NULL),
          "graphviz render failed")

   -- Extract bounding box.
   local x0, y0, x1, y1
      = extractNumbers(4, getAttribute(graphvizGraph, 'bb'), ",")
   local w = x1 - x0
   local h = y1 - y0
   local bbox = { x0, y0, w, h }

   -- Extract node positions.
   local positions = torch.zeros(nNodes, 2)
   for node in nodeIterator(graphvizGraph) do
      local id = getID(node)
      local x, y = getRelativePosition(node, bbox)
      positions[id][1] = x
      positions[id][2] = y
   end

   -- Clean up.
   graphviz.gvFreeLayout(context, graphvizGraph)
   cgraph.agclose(graphvizGraph)
   graphviz.gvFreeContext(context)
   return positions
end

function graph.graphvizFile(g, algorithm, fname)
   if not graphvizOk or not cgraphOk then
      error("graphviz library could not be loaded.")
   end
   algorithm = algorithm or 'dot'
   local _,_,rendertype = fname:reverse():find('(%a+)%.%w+')
   rendertype = rendertype:reverse()

   local context = graphviz.gvContext()
   local graphvizGraph = cgraph.agmemread(g:todot())

   assert(0 == graphviz.gvLayout(context, graphvizGraph, algorithm),
          "graphviz layout failed")

   local fhandle = ffi.C.fopen(fname, 'w')
   local ret = graphviz.gvRender(context, graphvizGraph, rendertype, fhandle)
   ffi.C.fclose(fhandle)
   assert(0 == ret, "graphviz render failed")

   graphviz.gvFreeLayout(context, graphvizGraph)
   cgraph.agclose(graphvizGraph)
   graphviz.gvFreeContext(context)
end

--[[
Given a graph, dump an SVG or display it using graphviz.

Args:
* `g` - graph to display
* `title` - Title to display in the graph
* `fname` - [optional] if given it should contain a file name without an extension,
the graph is saved on disk as fname.svg and display is not shown. If not given
the graph is shown on qt display (you need to have qtsvg installed and running qlua)

Returns:
* `qs` - the window handle for the qt display (if fname given) or nil
]]
function graph.dot(g,title,fname)
   local qt_display = fname == nil
   fname = fname or os.tmpname()
   local fnsvg = fname .. '.svg'
   local fndot = fname .. '.dot'
   graph.graphvizFile(g, 'dot', fnsvg)
   graph.graphvizFile(g, 'dot', fndot)
   if qt_display then
      require 'qtsvg'
      local qs = qt.QSvgWidget(fnsvg)
      qs:show()
      os.remove(fnsvg)
      os.remove(fndot)
      return qs
   end
end
