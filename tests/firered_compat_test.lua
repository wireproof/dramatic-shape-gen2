package.path = "./?.lua;./?/init.lua;" .. package.path

local Version = require("src.core.GameVersion")
Version.set("firered")

local T = require("tests.modkit")
local path = os.getenv("DS_MOD_PATH") or "mods/DramaticShapeVoxelMod"
local run = T.sdk.loadMod(path, {
  generation = 3,
  data = T.sdk.gen3Data(),
})

T.eq(#run.errors, 0,
  "Dramatic Shape loads cleanly on FireRed: " .. table.concat(run.errors, "; "))
T.check(run.loader.exports.DRAMATIC_SHAPE ~= nil,
  "Dramatic Shape exports are available on FireRed")
local pipelines = run.data.render_pipelines or {}
T.check(type(pipelines.voxel) == "table"
    and type(pipelines.voxel.drawWorld) == "function",
  "FireRed selects the native Gen III voxel renderer")
T.eq(pipelines.voxel.hotkey, "3",
  "FireRed voxel view keeps the shared pipeline hotkey")
T.check(type(pipelines.tiltshift) == "table"
    and type(pipelines.tiltshift.worldPresent) == "function",
  "FireRed registers the native tilt-shift world pass")
T.eq(pipelines.tiltshift.hotkey, "6",
  "FireRed tilt-shift pass keeps its declared hotkey")
T.eq(run.loader.exports.DRAMATIC_SHAPE.version, "1.5.5",
  "FireRed exports the upstream Gen III renderer revision")
T.check(type(run.loader.exports.DRAMATIC_SHAPE.lib) == "table",
  "FireRed exposes its native Gen III module namespace")

run.release()
T.finish("Dramatic Shape FireRed compatibility")
