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

mod.content.render_pipelines:register("dramatic_firered", {
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

mod.options:define({
  { key = "firered_strength", label = "FIRERED LOOK", type = "choice",
    default = 1, choices = {
      { "OFF", 0 }, { "SOFT", 1 }, { "MEDIUM", 2 }, { "STRONG", 3 },
    } },
})

local function applyDefault(game)
  local Pipelines = require("src.render.Pipelines")
  local options = game and game.options or {}
  options.pipelines = options.pipelines or {}
  if options.pipelines.dramatic_firered == nil then
    Pipelines.setLevel("dramatic_firered",
      tonumber(mod.options:get("firered_strength")) or 1)
    Pipelines.syncOptions(options)
    if game and game.writeOptions then game:writeOptions() end
  end
end

mod.events:on("game.ready", function(payload) applyDefault(payload and payload.game) end)
mod.events:on("mod.options_changed", function(payload)
  if payload and payload.mod == mod.id and payload.key == "firered_strength" then
    require("src.render.Pipelines").setLevel("dramatic_firered",
      tonumber(mod.options:get("firered_strength")) or 0)
  end
end)

mod.exports.version = "1.8.0-multigen.1"
mod.exports.mode = "firered-miniature"
mod.exports.isLoading = function() return false end
