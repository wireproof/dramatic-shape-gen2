-- Generation dispatcher.  Red/Blue/Yellow and Gold/Silver/Crystal retain the
-- complete voxel renderer; FireRed uses the native 240x160-safe compatibility
-- renderer because its GBA maps are not src.world.Map meshes.
local mod = ...
local GameVersion = require("src.core.GameVersion")
local info = GameVersion.info and GameVersion.info()
local file = info and info.generation == 3 and "firered.lua" or "main.lua"
local source = assert(mod:read(file), "DRAMATIC_SHAPE: missing " .. file)
local chunk = assert(load(source, "@" .. mod.path .. "/" .. file))
return chunk(mod)
