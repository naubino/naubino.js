import {Background} from './Background'
import {Menu} from './Menu'
import {Overlay} from './Overlay'
import {StandardGame} from './StandardGame'
import {TestCase} from './TestCase'
import {Session} from './session/Session'

export class LayerManager

  setup_session: ->
    @session = new Session this

  # lifecycle lives in Session now, these keep Naubino.play() & co working
  init:   (args...) -> @session.init args...
  play:   (args...) -> @session.play args...
  pause:  (args...) -> @session.pause args...
  stop:   (args...) -> @session.stop args...
  loose:  (args...) -> @session.loose args...
  toggle: -> @session.toggle()
  can:    (event) -> @session.can event

  setup_layers: ->
    @background    = new Background   @canvases.background_canvas
    @menu          = new Menu         @canvases.menu_canvas
    @overlay       = new Overlay      @canvases.overlay_canvas
    @game_standard = new StandardGame @canvases.game_canvas

    #Naubino.settings.canvas.width  = window.screen.width  * .7
    #Naubino.settings.canvas.height = window.screen.height * .7 - 15

    @game_testcase = new TestCase(@game_canvas)
    @game          = @game_standard
    #@game          = @game_testcase
    #@game = new Game @game_canvas
    @layers = [ @background, @game, @menu, @overlay ]

    for game in [ @game_standard, @game_testcase ]
      game.overflow_warning.add (severity) => @background.warn_overflow severity
      game.basket_changed.add => @background.draw()

    for layer, index in @layers
      layer.fps_label_depth = @layers.length - 1 - index

    @start_loop()

  start_loop: ->
    return if @animation_frame_id?
    last = performance.now()
    tick = (now) =>
      dt   = now - last
      last = now
      layer.advance(dt) for layer in @layers
      @animation_frame_id = requestAnimationFrame tick
    @animation_frame_id = requestAnimationFrame tick

  stop_loop: ->
    cancelAnimationFrame @animation_frame_id if @animation_frame_id?
    @animation_frame_id = null

  center: () ->
    win_width   = window.innerWidth #screen.width
    game_width  = document.querySelector("canvas#game_canvas").clientWidth
    left = win_width/2 - game_width/2
    document.querySelector('form').style.left = "#{left}px"
    for layer in @layers then layer.canvas.style.left = "#{left}px"


  scale_to: (scale) ->
    @scale = Naubino.settings.canvas.scale = scale
    for layer in @layers
      layer.scale_to scale
    # resizing wipes the canvases, don't wait for the next frame (paused layers have none)
    layer.draw() for layer in [@background, @game, @menu]

  demaximize: -> @scale_to 1

  # css px available for the canvases
  available_size: ->
    canvas = @game_canvas
    border = canvas.offsetWidth - canvas.clientWidth
    width:  window.innerWidth  - border
    height: window.innerHeight - canvas.offsetTop - border

  maximize: ->
    { width, height } = Naubino.settings.canvas
    avail = @available_size()
    console.info "viewport size", window.innerWidth, window.innerHeight
    @scale_to Math.max 0.1, Math.min(avail.width / width, avail.height / height)

  # short side keeps the base size (the basket needs it at max level),
  # long side follows the viewport's aspect ratio
  fit_field_to_viewport: ->
    @base_field ?= { width: Naubino.settings.canvas.width, height: Naubino.settings.canvas.height }
    short = Math.min @base_field.width, @base_field.height
    { width, height } = @available_size()
    if width >= height
      @resize_field Math.round(short * width / height), short
    else
      @resize_field short, Math.round(short * height / width)

  resize_field: (width, height) ->
    Naubino.settings.canvas.width  = width
    Naubino.settings.canvas.height = height
    for layer in @layers
      layer.width  = width
      layer.height = height
    # naubs hang on springs anchored at the old center
    center = @game.center()
    @game.for_each (naub) ->
      naub.center = center.Copy()
      naub.constraints?.center?.anchr2 = center.Copy()

  stretch: (width = "100%")->
    for name in 'background game menu overlay'.split ' '
      document.querySelector("canvas##{name}_canvas").style.width = width
    #console.log @scale = $("canvas#game_canvas").width()/Naubino.settings.canvas.width


  list_states: ->
    @session.name = "Naubino"
    for o in [ @session, @menu, @game, @overlay, @background]
      switch o.current
        when 'playing' then console.info o.name, o.current, o.fps, o.step_rate
        when 'paused'  then console.warn o.name, o.current, o.fps, o.step_rate
        when 'stopped' then console.warn o.name, o.current, o.fps, o.step_rate
        else console.error o.name, o.current

