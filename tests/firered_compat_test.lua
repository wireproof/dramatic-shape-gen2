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
  and run.data.render_pipelines.dramatic_firered_view
T.check(type(def) == "table" and type(def.present) == "function",
  "FireRed registers a final-frame render pipeline")
T.eq(def and def.hotkey, "6", "FireRed compatibility look has a mobile-safe hotkey")
T.eq(run.loader.exports.DRAMATIC_SHAPE.version, "1.8.0-multigen.3",
  "FireRed exports the repaired port revision")
local hooks = T.record.hooks(run.loader)
T.eq(hooks:depth("input.gamepad"), 1,
  "FireRed installs the physical SELECT seam")

local Pipelines = require("src.render.Pipelines")
Pipelines.install(run.data)
local writes = 0
local game = {
  phase = "field", session = {}, options = { pipelines = {} },
  zoomGateOK = function() return true end,
  writeOptions = function() writes = writes + 1 end,
}
run.loader.events:emit("game.ready", { game = game })
T.eq(game.options.pipelines.dramatic_firered_view, 0,
  "FireRed starts with the native frame untouched")
T.eq(run.loader.exports.DRAMATIC_SHAPE.cycleFireRedLook(game), true,
  "the FireRed look ladder accepts a free-roam step")
T.eq(game.options.pipelines.dramatic_firered_view, 1,
  "the exported FireRed look step advances the pipeline")
game.options.pipelines.dramatic_firered_view = 0
run.loader.events:emit("game.ready", { game = game })
writes = 0
run.loader.hooks:call("input.gamepad", function() end, game,
  { phase = "pressed", button = "back" })
T.eq(game.options.pipelines.dramatic_firered_view, 1,
  "bare SELECT cycles the FireRed look")
T.eq(writes, 1, "SELECT persists the selected FireRed look")
game.session.registeredItem = 42
run.loader.hooks:call("input.gamepad", function() end, game,
  { phase = "pressed", button = "back" })
T.eq(game.options.pipelines.dramatic_firered_view, 1,
  "a registered FireRed field item retains SELECT")

run.release()
T.finish("Dramatic Shape FireRed compatibility")
