--
-- goif
--
-- Copyright (c) 2016 BearishMushroom
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local goif = goif or {}

goif.frame = 0
goif.active = false
goif.canvas = nil
goif.width = 0
goif.height = 0
goif.data = {}

local path = (...):match("(.-)[^%.]+$")
path = path:gsub('(%.)', '\\')

local libname = 'none'
if jit.arch == 'x86' then
  libname = 'libgoif_32.dll'
elseif jit.arch == 'x64' then
  libname = 'libgoif_64.dll'
else
  error("ERROR, UNSUPPORTED ARCH")
end

local lib = package.loadlib(path .. libname, 'luaopen_libgoif')
lib = lib()

local function bind()
  love.graphics.setCanvas(goif.canvas)
  love.graphics.clear()
end

local function unbind()
  love.graphics.setCanvas()
end

goif.start = function()
  goif.frame = 0
  goif.data = {}
  goif.active = true
  if goif.canvas == nil then
    goif.width = love.graphics.getWidth()
    goif.height = love.graphics.getHeight()
    goif.canvas = love.graphics.newCanvas(goif.width, goif.height)
  end
end

goif.stop = function(file, verbose)
  file = file or "gif.gif"
  verbose = verbose or false
  goif.active = false

  if verbose then
    print("Frames: " .. tostring(#goif.data))
  end

  lib.set_frames(goif.frame - 2, goif.width, goif.height, verbose) -- compensate for skipped frames

  love.filesystem.createDirectory("goif")
  for i = 3, #goif.data do -- skip 2 frames for allocation lag
    local e = goif.data[i]
    lib.push_frame(e:getPointer(), e:getSize(), verbose)
  end

  lib.save(file, verbose)
  goif.data = {}
  collectgarbage()
end

goif.start_frame = function()
  if goif.active then
    bind()
  end
end

goif.end_frame = function()
  if goif.active then
    unbind()
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(goif.canvas)
    goif.data[goif.frame + 1] = goif.canvas:newImageData(0, 0, goif.width, goif.height)
    goif.frame = goif.frame + 1
  end
end

goif.submit_frame = function(canvas)
  goif.data[goif.frame + 1] = canvas:newImageData(0, 0, goif.width, goif.height)
  goif.frame = goif.frame + 1
end

return goif