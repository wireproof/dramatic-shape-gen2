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
T.eq(run.loader.exports.DRAMATIC_SHAPE.mode, "firered-miniature",
  "FireRed selects the native miniature renderer")
local def = run.data.render_pipelines
  and run.data.render_pipelines.dramatic_firered
T.check(type(def) == "table" and type(def.present) == "function",
  "FireRed registers a final-frame render pipeline")
T.eq(def and def.hotkey, "6", "FireRed compatibility look has a mobile-safe hotkey")

run.release()
T.finish("Dramatic Shape FireRed compatibility")
