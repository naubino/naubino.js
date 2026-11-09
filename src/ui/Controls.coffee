import {Util} from '../core/Util'

FULLSCREEN_EVENTS = ["fullscreenchange", "webkitfullscreenchange", "mozfullscreenchange"]

# Binds checkboxes to settings and applies the side effects of setting changes.
# Settings are the source of truth, checkboxes are just view + input.
export class Controls
  constructor: (@naubino, {@on_layout} = {}) ->
    @settings = @naubino.settings

  bind: ->
    @bind_checkbox '#fullScreenCheck', 'graphics.fullscreen'
    @bind_checkbox '#effectsCheck', 'graphics.effects'
    @bind_checkbox '#soundCheck', 'audio.muted', true
    @bind_checkbox '#constraintsCheck', 'graphics.draw_constraints'

    @settings.watch 'graphics.fullscreen', (on_) => @apply_fullscreen on_
    @settings.watch 'graphics.effects', => @apply_effects()

    on_change = =>
      @settings.set 'graphics.fullscreen', Util.isFullscreen()
      @on_layout?()
    document.addEventListener event, on_change, false for event in FULLSCREEN_EVENTS
    this

  bind_checkbox: (selector, path, inverted = false) ->
    checkbox = document.querySelector selector
    # inverted: checkbox shows the opposite of the setting (e.g. "sound" vs. audio.muted)
    to_view = (value) -> !!value isnt inverted
    checkbox.checked = to_view @settings.get path
    checkbox.addEventListener 'change', => @settings.set path, to_view checkbox.checked
    @settings.watch path, (value) -> checkbox.checked = to_view value

  apply_fullscreen: (on_) ->
    if on_
      Util.requestFullscreen().then (ok) =>
        @settings.set 'graphics.fullscreen', false unless ok
    else
      Util.exitFullscreen()

  apply_effects: ->
    effects = @settings.graphics.effects
    for layer in @naubino.layers
      if effects
        layer.refresh_draw_rate(layer.min_fps) if layer.min_fps?
        layer.refresh_step_rate(layer.min_step_rate) if layer.min_step_rate?
      else
        layer.refresh_draw_rate(layer.default_fps)
        layer.refresh_step_rate(layer.default_step_rate)
