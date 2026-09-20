-- Generation dispatcher. Keep each renderer on the engine generation it was
-- authored against: Red/Blue/Yellow use the mature Gen I + Stadium tree,
-- Gold/Silver/Crystal use UNDERdecoded's native Gen2Recomped tree vendored
-- under gen2/, and FireRed uses the separate Gen III tree under gen3/.
local mod = ...
local GameVersion = require("src.core.GameVersion")
local info = GameVersion.info and GameVersion.info()
local generation = info and info.generation or 1
local root = generation == 3 and "gen3"
  or generation == 2 and "gen2" or nil
local file = root and (root .. "/main.lua") or "main.lua"
local source = assert(mod:read(file), "DRAMATIC_SHAPE: missing " .. file)
local chunk = assert(load(source, "@" .. mod.path .. "/" .. file))

-- The Gen III runtime already prefixes all of its reads with gen3/.  Gen II
-- is the upstream standalone tree and expects its mod root to be relocated.
if not root or root == "gen3" then return chunk(mod) end

-- Vendored runtimes load their own lib/ and data/ files through mod:read().
-- Present a rooted view without changing any of the live mod services
-- (content registries, hooks, events, settings, saves, world/battle facades).
local rooted = setmetatable({
  path = mod.path .. "/" .. root,
  read = function(_, relative) return mod:read(root .. "/" .. relative) end,
}, { __index = mod, __newindex = mod })
return chunk(rooted)
