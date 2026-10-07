#upper case function to avoid overwriting defaults
cp.Vect::Copy   = -> new cp.Vect @.x, @.y
cp.Vect::Length = -> Math.sqrt(@.x * @.x + @.y * @.y)
cp.Vect::Angle  = -> cp.v.toangle(this)
cp.Vect::IsZero = -> @x == @y == 0
cp.Vect::AddPolar = (dir, len) ->
    @x += Math.cos(dir) * len
    @y += Math.sin(dir) * len

# cp.js 6.1.2 bug: BBTree::reindexQuery calls collideStatic(this, staticIndex, func)
# but the signature is (staticIndex, func). Hits whenever the static index is empty.
collideStatic = cp.SpatialIndex::collideStatic
cp.SpatialIndex::collideStatic = (staticIndex, func) ->
  [staticIndex, func] = [func, arguments[2]] if typeof func isnt 'function'
  collideStatic.call this, staticIndex, func

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


  shouldMaximize: -> $("#maximizeCheck").is(":checked") or @isFullscreen()

  isTouch: -> document.documentElement.classList.contains "touch"

  toggleMaximized: (force = false) ->
    if force or @shouldMaximize()
      Naubino.fit_field_to_viewport()# if @isTouch()
      Naubino.maximize()
    else
      Naubino.demaximize()
    window.Naubino.center()

  # debounced; mobile browsers report the final viewport size late (rotation, toolbars, fullscreen)
  relayout: (delay = 150) ->
    clearTimeout @relayout_timeout
    @relayout_timeout = setTimeout (=>
      if @shouldMaximize()
        Naubino.fit_field_to_viewport() if @isTouch()
        Naubino.maximize()
      Naubino.center()
    ), delay

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
  isFullscreen: ->
    !!(document.fullscreenElement or document.webkitFullscreenElement or document.mozFullScreenElement)

  requestFullscreen: ->
    el = document.documentElement
    request = el.requestFullscreen ? el.webkitRequestFullscreen ? el.webkitRequestFullScreen ? el.mozRequestFullScreen
    unless request?
      # e.g. iPhone Safari has no element fullscreen
      $('#fullScreenCheck').prop 'checked', false
      return
    Promise.resolve(request.call el).then(
      # game is 16:9, portrait on a phone would be tiny
      (-> screen.orientation?.lock?('landscape')?.catch? (->)),
      (-> $('#fullScreenCheck').prop 'checked', false)
    )

  exitFullscreen: ->
    return unless @isFullscreen()
    exit = document.exitFullscreen ? document.webkitExitFullscreen ? document.webkitCancelFullScreen ? document.mozCancelFullScreen
    exit?.call document

  changeFullscreen: ->
    # keep checkbox in sync when leaving via Esc / back gesture
    $('#fullScreenCheck').prop 'checked', @isFullscreen()
    @toggleMaximized()
    @relayout()
