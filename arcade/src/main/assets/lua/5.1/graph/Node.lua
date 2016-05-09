
--[[
Node class. This class is generally used with edge to add edges into a graph.
graph:add(graph.Edge(graph.Node(),graph.Node()))

But, one can also easily use this node class to create a graph. It will register
all the edges into its children table and one can parse the graph from any given node.
The drawback is there will be no global edge table and node table, which is mostly useful
to run algorithms on graphs. If all you need is just a data structure to store data and
run DFS, BFS over the graph, then this method is also quick and nice.
--]]
local Node = torch.class('graph.Node')

function Node:__init(d,p)
   self.data = d
   self.id = 0
   self.children = {}
   self.visited = false
   self.marked = false
end

function Node:add(child)
   local children = self.children
   if type(child) == 'table' and not torch.typename(child) then
      for i,v in ipairs(child) do
         self:add(v)
      end
   elseif not children[child] then
      table.insert(children,child)
      children[child] = #children
   end
end

-- visitor
function Node:visit(pre_func,post_func)
   if not self.visited then
      if pre_func then pre_func(self) end
      for i,child in ipairs(self.children) do
         child:visit(pre_func, post_func)
      end
      if post_func then post_func(self) end
   end
end

function Node:label()
   return tostring(self.data)
end

-- Create a graph from the Node traversal
function Node:graph()
   local g = graph.Graph()
   local function build_graph(node)
      for i,child in ipairs(node.children) do
         g:add(graph.Edge(node,child))
      end
   end
   self:bfs(build_graph)
   return g
end

function Node:dfs_dirty(func)
   local visitednodes = {}
   local dfs_func = function(node)
      func(node)
      table.insert(visitednodes,node)
   end
   local dfs_func_pre = function(node)
      node.visited = true
   end
   self:visit(dfs_func_pre, dfs_func)
   return visitednodes
end
function Node:dfs(func)
   for i,node in ipairs(self:dfs_dirty(func)) do
      node.visited = false
   end
end

function Node:bfs_dirty(func)
   local visitednodes = {}
   local bfsnodes = {}
   local bfs_func = function(node)
      func(node)
      for i,child in ipairs(node.children) do
         if not child.marked then
            child.marked = true
            table.insert(bfsnodes,child)
         end
      end
   end
   table.insert(bfsnodes,self)
   self.marked = true
   while #bfsnodes > 0 do
      local node = table.remove(bfsnodes,1)
      table.insert(visitednodes,node)
      bfs_func(node)
   end
   return visitednodes
end

function Node:bfs(func)
   for i,node in ipairs(self:bfs_dirty(func)) do
      node.marked = false
   end
end

function Node:hasCycle()

   local hascycle = false
   local explorednodes = {}

   local function pre(node)
      -- if someone found a cycle, just back up
      if hascycle then return hascycle end
      -- if this node was marked during dfs, then
      -- it is still being explored, which means we hit a cycle.
      if node.marked then
         -- at this point set visited to true so that Node:visit() does
         -- not explore this node again
         node.visited = true
         hascycle = true
         return hascycle
      end
      node.marked = true
   end

   local function post(node)
      -- we are done with this node, so just remove marked info
      node.marked = false
      -- set visited to true flagging that this node is done.
      -- we might hit it in the future through a separate path, but 
      -- at that point we should not explore it, the Node:visit()
      -- will avoid visiting any visited node.
      node.visited = true
      explorednodes[node] = true
   end

   self:visit(pre, post)

   -- now clean-up all the nodes
   for node, _ in pairs(explorednodes) do
      node.visited = false
   end

   return hascycle
end
