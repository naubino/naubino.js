export class Viewport

  constructor: (@container, canvas_settings, {centered_elements = []} = {}) ->
    @base_size = Object.freeze
      width: canvas_settings.width
      height: canvas_settings.height
    @width = @base_size.width
    @height = @base_size.height
    @scale = 1
    @centered_elements = centered_elements
    @layers = []
    @redraw_layers = []
    @canvases = {}

    for name in 'background game menu overlay'.split ' '
      canvas_name = "#{name}_canvas"
      canvas = document.createElement 'canvas'
      canvas.width = @width
      canvas.height = @height
      canvas.setAttribute 'id', canvas_name
      @container.appendChild canvas
      @canvases[canvas_name] = canvas

  set_layers: (layers, redraw_layers) ->
    @layers = layers
    @redraw_layers = redraw_layers ? layers

    for layer, index in @layers
      layer.fps_label_depth = @layers.length - 1 - index

  center: ->
    game_width = @canvases.game_canvas.clientWidth
    left = window.innerWidth / 2 - game_width / 2
    element.style.left = "#{left}px" for element in @centered_elements
    layer.canvas.style.left = "#{left}px" for layer in @layers

  scale_to: (scale) ->
    @scale = scale
    layer.scale_to scale for layer in @layers
    layer.draw() for layer in @redraw_layers

  demaximize: -> @scale_to 1

  available_size: ->
    canvas = @canvases.game_canvas
    border = canvas.offsetWidth - canvas.clientWidth
    width: window.innerWidth - border
    height: window.innerHeight - canvas.offsetTop - border

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

  to_local: (clientX, clientY, canvas = @canvases.overlay_canvas) ->
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
    canvas.style.width = width for name, canvas of @canvases
