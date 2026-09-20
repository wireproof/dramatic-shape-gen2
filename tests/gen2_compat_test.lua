package.path = "./?.lua;./?/init.lua;" .. package.path

local Version = require("src.core.GameVersion")
assert(Version.set and Version.generation,
  "Dramatic Shape Gen2 compatibility test requires Gen2Recomped")
Version.set("gold")
assert(Version.generation() == 2,
  "Dramatic Shape Gen2 compatibility test requires a Gen II game")

local T = require("tests.modkit")
local path = os.getenv("DS_MOD_PATH") or "mods/DramaticShapeVoxelMod"
local run = T.sdk.loadMod(path, { data = T.fixtures.load(), generation = 2 })

T.eq(#run.errors, 0,
  "Dramatic Shape Gen2 port loads clean: " .. table.concat(run.errors, "; "))
local loaded = run.loader.mods.DRAMATIC_SHAPE
T.eq(loaded and loaded.manifest.version, "1.8.0-multigen.3",
  "the Gen2 forward-port carries its own revision")

local V = run.loader.exports.DRAMATIC_SHAPE.lib
local profile = V.data("voxel_heights")
T.check(type(profile.tilesets.TilesetJohto) == "table",
  "the Johto outdoor tileset has an authored shape profile")
T.check(type(profile.tilesets.TilesetJohtoModern) == "table",
  "the modern Johto outdoor tileset has an authored shape profile")
T.check(type(profile.tilesets.TilesetKanto) == "table",
  "postgame Kanto keeps its own Generation II tileset profile")
T.check(type(profile.buildings.TilesetJohto) == "table"
        and #profile.buildings.TilesetJohto > 0,
  "Johto building templates survived the 1.8.0 forward-port")
T.check(type(profile.buildings.TilesetKanto) == "table"
        and #profile.buildings.TilesetKanto > 0,
  "Generation II Kanto building templates survived the forward-port")

local TerrainAtlas = V.require("TerrainAtlas")
local TileShape = V.require("TileShape")
local Structures = V.require("Structures")
local shapes = TileShape.forMap({ tileset = {
  id = "TilesetJohto", collision = {}, imageWidth = 128, imageHeight = 48,
} })
for _, class in ipairs({ "column", "shell", "terrace", "waterfall" }) do
  T.check(type(shapes.classes[class]) == "table",
    "Generation II structure class is present: " .. class)
end

T.check(type(TerrainAtlas.forMap) == "function",
  "the Generation II-aware atlas entry point is available")
T.check(type(TileShape.forMap) == "function"
        and type(TileShape.at) == "function",
  "collision-class shape resolution is available")
T.check(type(Structures.runHeight) == "function",
  "raised Generation II ground can report its measured height")

-- SELECT has an overworld job in Generation II: a registered key item must
-- win over Dramatic Shape's camera shortcut. Exercise the predicate captured
-- by the installed OverworldController wrapper directly so the test does not
-- need to simulate a complete movement frame.
local Controller = require("src.world.OverworldController")
local function findUpvalue(fn, wanted, seen)
  if type(fn) ~= "function" then return nil end
  seen = seen or {}
  if seen[fn] then return nil end
  seen[fn] = true
  for i = 1, debug.getinfo(fn, "u").nups do
    local name, value = debug.getupvalue(fn, i)
    if name == wanted then return value end
    local nested = findUpvalue(value, wanted, seen)
    if nested ~= nil then return nested end
  end
  return nil
end
local registeredItemOwnsSelect =
  findUpvalue(Controller.handleInput, "registeredItemOwnsSelect")
T.check(type(registeredItemOwnsSelect) == "function",
  "the Gen2 SELECT ownership guard is installed")
local game = {
  save = { registeredItem = "BICYCLE", inventory = { BICYCLE = true } },
  data = { items = { BICYCLE = { registerable = true } } },
}
T.eq(registeredItemOwnsSelect(game), true,
  "a valid registered item keeps SELECT in Gold/Silver")
game.save.inventory.BICYCLE = nil
T.eq(registeredItemOwnsSelect(game), false,
  "a stale registration does not reserve SELECT")

run.release()
T.finish("Dramatic Shape Gen2 compatibility")
