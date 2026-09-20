-- FireRed compatibility renderer for Dramatic Shape.
--
-- FireRed's maps are composed by src/core/game3 rather than src.world.Map,
-- so the Gen I/II voxel mesher has no truthful geometry to consume.  This
-- path keeps the mod useful and safe on FireRed with its miniature-camera
-- signature: a selective-focus blur, saturation lift and soft vignette over
-- the native 240x160 frame.  The complete voxel path remains unchanged on
-- generations I and II.

local mod = ...
local shader, ping, pong, cw, ch
local level = 0
local PIPELINE_ID = "dramatic_firered_view"

local SHADER = [[
  uniform vec2 direction;
  uniform float strength;
  uniform float finalPass;
  vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
    float focus = smoothstep(0.10, 0.48, abs(uv.y - 0.52));
    vec2 stepv = direction * mix(0.35, 2.5, strength) * focus;
    vec4 c = Texel(tex, uv) * 0.40;
    c += Texel(tex, uv + stepv) * 0.24;
    c += Texel(tex, uv - stepv) * 0.24;
    c += Texel(tex, uv + stepv * 2.0) * 0.06;
    c += Texel(tex, uv - stepv * 2.0) * 0.06;
    if (finalPass > 0.5) {
      float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
      c.rgb = mix(vec3(luma), c.rgb, 1.0 + strength * 0.20);
      vec2 d = uv - vec2(0.5);
      c.rgb *= 1.0 - dot(d, d) * (0.22 + strength * 0.16);
    }
    return c * color;
  }
]]

local function resources(w, h)
  if not shader then
    local ok, made = pcall(love.graphics.newShader, SHADER)
    if not ok then shader = false else shader = made end
  end
  if shader == false then return nil end
  if not ping or cw ~= w or ch ~= h then
    ping = love.graphics.newCanvas(w, h)
    pong = love.graphics.newCanvas(w, h)
    ping:setFilter("linear", "linear")
    pong:setFilter("linear", "linear")
    cw, ch = w, h
  end
  return shader, ping, pong
end

local function present(canvas)
  if level <= 0 then return canvas end
  local w, h = canvas:getWidth(), canvas:getHeight()
  local sh, a, b = resources(w, h)
  if not sh then return canvas end
  local G = love.graphics
  G.setBlendMode("alpha")
  G.setColor(1, 1, 1, 1)
  G.setShader(sh)
  sh:send("strength", level / 3)
  sh:send("direction", { 1 / w, 0 })
  sh:send("finalPass", 0)
  G.setCanvas(a)
  G.clear(0, 0, 0, 1)
  G.draw(canvas)
  sh:send("direction", { 0, 1 / h })
  sh:send("finalPass", 1)
  G.setCanvas(b)
  G.clear(0, 0, 0, 1)
  G.draw(a)
  G.setCanvas()
  G.setShader()
  return b
end

mod.content.render_pipelines:register(PIPELINE_ID, {
  label = "DRAMATIC",
  levels = { "OFF", "SOFT", "MEDIUM", "STRONG" },
  hotkey = "6",
  priority = 100,
  gate = function() return true end,
  available = function()
    return love and love.graphics and love.graphics.newShader
      and love.graphics.newCanvas and true or false
  end,
  update = function(_, current) level = current or 0 end,
  present = present,
  invalidate = function()
    if ping and ping.release then pcall(ping.release, ping) end
    if pong and pong.release then pcall(pong.release, pong) end
    ping, pong, shader, cw, ch = nil, nil, nil, nil, nil
  end,
})

local function applySavedLevel(game)
  local Pipelines = require("src.render.Pipelines")
  local options = game and game.options or {}
  options.pipelines = options.pipelines or {}
  -- This new id intentionally does not inherit the old compatibility pass,
  -- which defaulted to SOFT even when the visible T-SHIFT row said OFF.
  -- Existing installs therefore migrate to a genuinely untouched frame.
  Pipelines.setLevel(PIPELINE_ID,
    tonumber(options.pipelines[PIPELINE_ID]) or 0)
  Pipelines.syncOptions(options)
end

local function registeredItemOwnsSelect(game)
  return game and game.session and game.session.registeredItem ~= nil
end

local function cycleLook(game)
  if not (game and game.zoomGateOK and game:zoomGateOK()) then return false end
  if registeredItemOwnsSelect(game) then return false end
  local Pipelines = require("src.render.Pipelines")
  Pipelines.cycle(PIPELINE_ID, 1)
  Pipelines.syncOptions(game.options)
  if game.writeOptions then game:writeOptions() end
  return true
end

mod.events:on("game.ready", function(payload)
  applySavedLevel(payload and payload.game)
end)

-- FireRed cannot consume the Gen I/II voxel mesh, but SELECT should still be
-- useful on a handheld: cycle the honest native-frame look ladder. Consume a
-- physical pad/key press only when no registered field item owns SELECT.
mod.hooks:wrap("input.gamepad", function(next, game, event)
  if event and event.phase == "pressed"
      and (event.button == "back" or event.button == "select")
      and cycleLook(game) then
    return
  end
  return next(game, event)
end, 1000)

mod.hooks:wrap("input.key", function(next, game, event)
  if event and event.phase == "pressed"
      and (event.key == "tab" or event.key == "lshift"
        or event.key == "rshift")
      and cycleLook(game) then
    return
  end
  return next(game, event)
end, 1000)

mod.hooks:wrap("input.step", function(next, game, dt)
  local result = next(game, dt)
  local input = game and game.input
  if input and input.wasPressed and input:wasPressed("select") then
    cycleLook(game)
  end
  return result
end, 1000)

mod.exports.version = "1.8.0-multigen.3"
mod.exports.mode = "firered-miniature"
mod.exports.isLoading = function() return false end
mod.exports.cycleFireRedLook = cycleLook
