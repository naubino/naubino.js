export class Viewport

  constructor: (@container, canvas_settings, options = {}) ->
    @base_size = Object.freeze
      width: canvas_settings.width
      height: canvas_settings.height
    @width = @base_size.width
    @height = @base_size.height
    @scale = 1
    @top_margin = 0
    @set_canvas_style @container,
      width: "#{@width}px"
      height: "#{@height}px"
      position: 'relative'
      zIndex: '0'
      isolation: 'isolate'
      margin: "#{@top_margin}px auto 0"
      touchAction: 'none'
    @centered_elements = options.centered_elements ? []
    for element in @centered_elements
      @set_canvas_style element, zIndex: '1'
    @events = options.events
    @layers = []
    @redraw_layers = []
    @leases = new Set

    @captures = {}
    @active_pointers = {}
    @gesture = null
    @on_pointerdown = (event) => @pointer_down event
    @on_pointermove = (event) => @pointer_move event
    @on_pointerup = (event) => @pointer_end event
    @on_pointercancel = (event) => @pointer_end event, yes
    @container.addEventListener 'pointerdown', @on_pointerdown
    @container.addEventListener 'pointermove', @on_pointermove
    @container.addEventListener 'pointerup', @on_pointerup
    @container.addEventListener 'pointercancel', @on_pointercancel

  lease: (depth = 0, class_name = null) ->
    canvas = document.createElement 'canvas'
    canvas.width = @width
    canvas.height = @height
    canvas.classList.add 'canvas', "canvas-depth-#{depth}"
    canvas.classList.add class_name if class_name?
    @set_canvas_style canvas,
      position: 'absolute'
      zIndex: "#{depth}"
      left: '50%'
      top: '0'
      transform: 'translateX(-50%)'
      touchAction: 'none'
    @container.appendChild canvas

    lease = {canvas, depth}
    @leases.add lease
    lease.release = =>
      return unless @leases.delete lease
      canvas.remove()
    lease

  set_canvas_style: (canvas, styles) ->
    canvas.style[name] = value for name, value of styles

  get_canvas_style: (canvas, name) -> canvas.style[name]

  pointer_down: (event) ->
    event.preventDefault()
    @container.setPointerCapture event.pointerId
    pointer_id = event.pointerId
    position = @pointer_position event
    @active_pointers[pointer_id] =
      pointer_type: event.pointerType
      position: position

    if @gesture?
      @gesture.eligible = no
    else if @touch_pointer_count() is 2
      @start_two_finger_gesture()
    else if @touch_pointer_count() > 2
      @gesture =
        started_at: Date.now()
        eligible: no
        ended: no
        origins: {}
      @end_pointer_captures()
      @events.input.two_finger_start.dispatch()
      @finish_two_finger_gesture()
    else
      for layer in @layers.slice().reverse()
        continue unless layer.pointer_start?
        continue if layer.accepts_pointer? and not layer.accepts_pointer(position)
        layer.pointer_start position
        @captures[pointer_id] = layer
        break

  pointer_move: (event) ->
    event.preventDefault()
    pointer_id = event.pointerId
    position = @pointer_position event
    pointer = @active_pointers[pointer_id]
    if pointer?
      pointer.position = position

    if @gesture?
      origin = @gesture.origins[pointer_id]
      if origin? and Math.hypot(position.x - origin.x, position.y - origin.y) > 10
        @gesture.eligible = no
    else if layer = @captures[pointer_id]
      layer.move_pointer? position.x, position.y
    else if event.pointerType is 'mouse'
      for layer in @layers.slice().reverse() when layer.name is 'menu'
        layer.move_pointer? position.x, position.y
        break

  pointer_end: (event, cancelled = no) ->
    event.preventDefault()
    pointer_id = event.pointerId
    delete @active_pointers[pointer_id]

    if @gesture?
      @gesture.eligible = no if cancelled
      @finish_two_finger_gesture() unless @gesture.ended
      if Object.keys(@active_pointers).length is 0
        tap = @gesture.eligible and Date.now() - @gesture.started_at < 400
        @gesture = null
        @events.input.two_finger_tap.dispatch() if tap
    else
      layer = @captures[pointer_id]
      layer.pointer_end?() if layer?
      delete @captures[pointer_id]

  pointer_position: (event) ->
    @to_local event.clientX, event.clientY

  touch_pointer_count: ->
    count = 0
    count++ for pointer_id, pointer of @active_pointers when pointer.pointer_type is 'touch'
    count

  start_two_finger_gesture: ->
    @gesture =
      started_at: Date.now()
      eligible: yes
      ended: no
      origins: {}

    for pointer_id, pointer of @active_pointers
      @gesture.origins[pointer_id] = pointer.position

    @end_pointer_captures()
    @events.input.two_finger_start.dispatch()

  end_pointer_captures: ->
    for pointer_id, layer of @captures
      layer.pointer_end?()
      delete @captures[pointer_id]

  finish_two_finger_gesture: ->
    return unless @gesture? and not @gesture.ended
    @gesture.ended = yes
    @events.input.two_finger_end.dispatch()

  dispose: ->
    @container.removeEventListener 'pointerdown', @on_pointerdown
    @container.removeEventListener 'pointermove', @on_pointermove
    @container.removeEventListener 'pointerup', @on_pointerup
    @container.removeEventListener 'pointercancel', @on_pointercancel
    @end_pointer_captures()
    @finish_two_finger_gesture()
    for pointer_id of @active_pointers
      @container.releasePointerCapture(pointer_id) if @container.hasPointerCapture(pointer_id)
    @gesture = null
    @active_pointers = {}
    lease.release() for lease from Array.from(@leases)

  set_layers: (layers, redraw_layers) ->
    @layers = layers
    @redraw_layers = redraw_layers ? layers

    for layer, index in @layers
      layer.fps_label_depth = @layers.length - 1 - index
      layer.set_fps_label_depth? layer.fps_label_depth

  reserve_controls_space: ->
    controls_height = Math.max 0, (element.offsetHeight for element in @centered_elements)...
    @set_canvas_style @container, marginTop: "#{@top_margin + controls_height}px"

  center: ->
    game_layer = (layer for layer in @layers when layer.name is 'game')[0]
    return unless game_layer?
    game_width = game_layer.canvas.clientWidth
    left = window.innerWidth / 2 - game_width / 2
    @reserve_controls_space()
    container_top = @container.getBoundingClientRect().top + window.scrollY
    for element in @centered_elements
      element.style.left = "#{left}px"
      if element.offsetHeight > 0
        element.style.top = "#{container_top - element.offsetHeight - @top_margin}px"

  scale_to: (scale) ->
    @scale = scale
    layer.scale_to scale for layer in @layers
    layer.draw() for layer in @redraw_layers

  demaximize: -> @scale_to 1

  available_size: ->
    @reserve_controls_space()
    game_layer = (layer for layer in @layers when layer.name is 'game')[0]
    canvas = game_layer?.canvas
    return {width: window.innerWidth, height: window.innerHeight} unless canvas?
    border = canvas.offsetWidth - canvas.clientWidth
    width: window.innerWidth - border
    height: window.innerHeight - @container.offsetTop - border

  maximize: ->
    avail = @available_size()
    @scale_to Math.max 0.1, Math.min(avail.width / @width, avail.height / @height)

  # Short side remains at the configured field size; long side follows the viewport.
  fit_field_to_viewport: ->
    short = Math.min @base_size.width, @base_size.height
    { width, height } = @available_size()
    if width >= height
      @resize_field Math.round(short * width / height), short
    else
      @resize_field short, Math.round(short * height / width)

  resize_field: (width, height) ->
    @width = width
    @height = height
    for layer in @layers
      layer.width = width
      layer.height = height
    @on_resize? width, height

  to_local: (clientX, clientY, canvas = null) ->
    canvas ?= (layer.canvas for layer in @layers when layer.name is 'overlay')[0]
    canvas ?= @layers[@layers.length - 1]?.canvas
    return {x: 0, y: 0} unless canvas?
    rect = canvas.getBoundingClientRect()
    x: (clientX - rect.left - canvas.clientLeft) / @scale
    y: (clientY - rect.top - canvas.clientTop) / @scale

  layout: ({maximized = no, fit = no} = {}) ->
    clearTimeout @layout_timeout
    if maximized
      @fit_field_to_viewport() if fit
      @maximize()
    else
      @demaximize()
    @center()

  schedule_layout: (options, delay = 150) ->
    clearTimeout @layout_timeout
    @layout_timeout = setTimeout (=> @layout options), delay

  stretch: (width = '100%') ->
    @set_canvas_style lease.canvas, {width} for lease from @leases
