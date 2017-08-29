import * as cp from 'chipmunk'

#upper case function to avoid overwriting defaults
cp.Vect::Copy   = -> new cp.Vect @.x, @.y
cp.Vect::Length = -> Math.sqrt(@.x * @.x + @.y * @.y)
cp.Vect::Angle  = -> cp.v.toangle(this)
cp.Vect::IsZero = -> @x == @y == 0
cp.Vect::AddPolar = (dir, len) ->
    @x += Math.cos(dir) * len
    @y += Math.sin(dir) * len

cp.Constraint::IsRogue= ->
  (@a.isRogue() and not @a.isStatic()) or
  (@b.isRogue() and not @b.isStatic())

export Util =
  shuffle: (a) ->
    b = a.slice()
    for x, i in b
      j = Math.floor Math.random() * b.length
      [b[i], b[j]] = [b[j], b[i]]
    b


  extend: (obj, mixin) ->
    for name, method of mixin
      #console.log name
      obj[name] = method

  include: (klass, mixin) ->
    @extend klass.prototype, mixin


  # turns the internal color init a string that applies to canvas
  color_to_rgba: (color, shift = 0) =>
    r = Math.round((color[0] + shift))
    g = Math.round((color[1] + shift))
    b = Math.round((color[2] + shift))
    a = color[3]
    if a?
      "rgba(#{r},#{g},#{b},#{a})"
    else
      "rgba(#{r},#{g},#{b},1)"

  interpolate_color: (a,b,s=0.5)->
    max = Math.min a.length, b.length
    for i in [0...max]
      @interpolate a[i],b[i],s


  interpolate: (a,b,s = 0.5)->
    d = b-a
    v = a + d*s

  togglePrerendering: ->
    Naubino.settings.graphics.updating =
      if $('#prerenderingCheck').is(":checked")
        off
      else
        on


  toggleMaximized: (force = false) ->
    if $("#maximizeCheck").is(":checked") or force
      Naubino.maximize()
    else
      Naubino.demaximize()
    window.Naubino.center()

  toggleEffects: ->
    if $('#effectsCheck').is(":checked")
      Naubino.settings.graphics.effects = on
      for layer in Naubino.layers
        layer.refresh_draw_rate(layer.min_fps) if layer.min_fps?
        layer.refresh_step_rate(layer.min_step_rate) if layer.min_step_rate?
    else
      Naubino.settings.graphics.effects = off
      for layer in Naubino.layers
        layer.refresh_draw_rate(layer.default_fps)
        layer.refresh_step_rate(layer.default_step_rate)

  toggleFullscreen: ->
    if $('#fullScreenCheck').is(":checked")
      @requestFullscreen()
    else
      @exitFullscreen()

  toggleAll: ->
    @toggleEffects()
    @toggleFullscreen()
    @toggleMaximized()
    @togglePrerendering



  # https://developer.mozilla.org/en/DOM/Using_full-screen_mode
  requestFullscreen: ->
    docElm = document.documentElement
    if (docElm.requestFullscreen?)
      docElm.requestFullscreen()
    else if (docElm.mozRequestFullScreen?)
      docElm.mozRequestFullScreen()
    else if (docElm.oRequestFullScreen?)
      docElm.oRequestFullScreen()
    else if (docElm.webkitRequestFullScreen?)
      docElm.webkitRequestFullScreen()

  exitFullscreen: ->
    if (document.exitFullscreen)
      document.exitFullscreen()
    else if (document.mozCancelFullScreen)
      document.mozCancelFullScreen()
    else if (document.webkitCancelFullScreen)
      document.webkitCancelFullScreen()


  changeFullscreen: (fullScreen) ->
    if fullScreen or (document.fullscreen) or (document.mozFullScreen) or (document.webkitIsFullScreen)
      @toggleMaximized(on)
    else
      @toggleMaximized()


