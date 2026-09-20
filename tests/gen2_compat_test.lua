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
T.eq(loaded and loaded.manifest.version, "1.8.0-multigen.6",
  "the Gen2 runtime carries the multigame release revision")

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

local Pipelines = require("src.render.Pipelines")
Pipelines.install(run.data)
T.check(Pipelines.get("voxel") ~= nil,
  "the native Gen2 runtime registers its voxel world pipeline")
T.check(Pipelines.get("voxel").drawWorld ~= nil,
  "the Gen2 voxel pipeline owns a real world pass")

run.release()
T.finish("Dramatic Shape Gen2 compatibility")
