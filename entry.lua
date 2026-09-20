-- Generation dispatcher. Red/Blue/Yellow and Gold/Silver/Crystal retain the
-- mature renderer plus Stadium support. Gen III uses the current upstream
-- geometry renderer (vendored under gen3/) instead of the old screen-space
-- blur compatibility effect.
local mod = ...
local GameVersion = require("src.core.GameVersion")
local info = GameVersion.info and GameVersion.info()
local file = info and info.generation == 3 and "gen3/main.lua" or "main.lua"
local source = assert(mod:read(file), "DRAMATIC_SHAPE: missing " .. file)
local chunk = assert(load(source, "@" .. mod.path .. "/" .. file))
return chunk(mod)
