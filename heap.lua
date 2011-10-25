-- Copyright (c) 2007-2011 Incremental IP Limited.

--[[
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Oct 2011 - Michal Kottman - simplified interface by removing keys.
	The heap stores only values, and comparator works directly on values.
--]]


local io = require("io")
local math = require("math")
local string = require("string")
local assert, ipairs, setmetatable, tostring = assert, ipairs, setmetatable, tostring
local math_floor = math.floor

module(...)

heap = _M

function heap:new(comparison, o)
  o = o or {}
  self.__index = self
  setmetatable(o, self)
  o.comparison = comparison or function(k1, k2) return k1 < k2 end
  return o
end

function heap:empty()
  return self[1] == nil
end

function heap:insert(value)
  assert(value, "You can't insert nil into a heap")
  
  local cmp = self.comparison

  local child_index = #self + 1
  while child_index > 1 do
    local parent_index = math_floor(child_index / 2)
    local parent_rec = self[parent_index]
    if cmp(value, parent_rec) then
      self[child_index] = parent_rec
    else
      break
    end
    child_index = parent_index
  end
  self[child_index] = value
end


function heap:pop()
  assert(self[1], "The heap is empty")

  local cmp = self.comparison

  local result = self[1]
  self[1] = nil
  
  local size = #self
  local last = self[size]
  self[size] = nil
  size = size - 1

  local parent_index = 1
  while parent_index * 2 <= size do
    local child_index = parent_index * 2
    if child_index+1 <= size and cmp(self[child_index+1], self[child_index]) then
      child_index = child_index + 1
    end
    local child_rec = self[child_index]
    if cmp(last, child_rec) then
      break
    else
      self[parent_index] = child_rec
      parent_index = child_index
    end
  end
  self[parent_index] = last
  return result
end
