########################################################
#     _   __            __    _                 _      #
#    / | / /___ ___  __/ /_  (_)___  ____      (_)____ #
#   /  |/ / __ `/ / / / __ \/ / __ \/ __ \    / / ___/ #
#  / /|  / /_/ / /_/ / /_/ / / / / / /_/ /   / (__  )  #
# /_/ |_/\__,_/\__,_/_.___/_/_/ /_/\____(_)_/ /____/   #
#                                        /___/         #
########################################################

# TODO questionable approach
# window.onload = ->
#   Naubino.constructor()


define ["Background", "Game", "Keybindings", "Menu", "Overlay", "StandardGame", "TestCase", "Settings", "Tutorial"], (Background, Game, KeyBindings, Menu, Overlay, StandardGame, TestCase, Settings, Tutorial) -> class Naubino
  constructor: () ->
    @name = "Naubino (chipmunk branch)"
    @settings = Settings
    @colors = @settings.colors.output
    @create_fsm()
    @Signal = window.signals.Signal
    @add_signals()
    @add_listeners()

  setup: ->
    @init_dom()
    @init_layers()

    @setup_keybindings()
    @setup_cursorbindings()
    console.timeEnd("loading")


  print: -> @gamediv.insertAdjacentHTML("afterend","<img src=\"#{@game_canvas.toDataURL()}\"/>")

  init_dom: () ->
    @gamediv = document.querySelector("#gamediv")
    @canvases = []
    { width, height } = @settings.canvas

    for name in 'background game menu overlay'.split ' '
      name += '_canvas'
      c = document.createElement 'canvas'
      c.width = width
      c.height = height
      c.setAttribute 'id', name
      @[name] = c
      @gamediv.appendChild c
      @canvases.push c

  init_layers: ->
    @gamediv.max-width     = @settings.canvas.width

    @background    = new Background(@background_canvas)
    @game_standard = new StandardGame(@game_canvas)
    @game_testcase = new TestCase(@game_canvas)
    @game_tutorial = new Tutorial(@game_canvas)
    @game          = @game_standard
    #@game          = @game_testcase
    #@game          = @game_tutorial
    @menu          = new Menu(@menu_canvas)
    @overlay       = new Overlay(@overlay_canvas)

    @menu.init()
    @menu.animation.play()
    @game.init()



  ###
  Everything has to have state
  ###
  create_fsm: ->
    StateMachine.create {
      target: this
      initial: {state : 'stopped' , event: 'init'}
      events: @settings.events
      error: (e, from, to, args, code, msg) -> console.error "#{@name}.#{e}: #{from} -> #{to}\n#{code}::#{msg}"
    }

  list_states: ->
    @.name = "Naubino"
    for o in [ @, @menu, @game, @overlay.animation, @menu.animation, @game.animation, @background.animation]
      switch o.current
        when 'playing' then console.info o.name, o.current
        when 'paused'  then console.warn o.name, o.current
        when 'stopped' then console.warn o.name, o.current
        else console.error o.name, o.current

  onchangestate: (e,f,t)-> console.info "Naubino changed states #{e}: #{f} -> #{t}"
  onbeforeplay: (event, from, to) -> @game.play()
  onenterplaying: -> @menu.play()

  toggle: ->
    switch @current
      when 'playing' then @pause()
      when 'paused'  then @play()
      when 'stopped'  then @play()

  onbeforepause: (event, from, to) ->
    unless from == "init"
      #console.time('state_paused')
      @game.pause()
      @menu.pause()

  onenterpaused: ->
    #console.timeEnd('state_paused')
    #@game.animation.pause()

  onpause: (event, from, to) ->

  onbeforestop: (event, from, to, @override = off) ->
    @game.stop()
    if @game.current == "stopped"
      @menu.stop()
    else
      false

  tutorial: ->
    @game_tutorial = new Tutorial(@game_canvas)
    @soft_switch @game_tutorial

  leave_tutorial: ->
    @soft_switch @oldgame
    @overlay       = new Overlay(@overlay_canvas)
    delete @game_tutorial
    delete @oldgame

  soft_switch: (new_game) ->
    @pause() if @current == "playing"
    @oldgame = @game

    @game.fade_out =>
      @game.clear()
      @game = new_game
      @game.draw()
      @game.init() if @game.current == "none"
      @game.fade_in => @play()


  scale: (nscale) ->
    console.log oscale = 1
    @settings.canvas.scale = nscale
    console.log ratio = nscale/oscale
    for canvas in  @canvases
      # doesnt work
      #canvas.width = @settings.canvas.width * ratio
      #canvas.height = @settings.canvas.height * ratio
      canvas.getContext('2d').scale ratio, ratio



  ###
  Signals connect everything else that does not react to events
  ###

  add_signals: ->
    # user interface
    @mousedown       = new @Signal()
    @mouseup         = new @Signal()
    @mousemove       = new @Signal()
    @keydown         = new @Signal()
    @keyup           = new @Signal()
    @touchstart      = new @Signal()
    @touchend        = new @Signal()
    @touchmove       = new @Signal()

    # menu
    @menu_button     = new @Signal()
    @menu_focus      = new @Signal()
    @menu_blur       = new @Signal()


  add_listeners: ->
    @menu_focus.add => @menu.hovering = @menu_button.active = true
    @menu_blur.add => @menu.hovering = @menu_button.active = false


  setup_keybindings: () ->
    @keybindings = new KeyBindings()
    window.onkeydown = (key) => @keybindings.keydown(key)
    window.onkeyup = (key) => @keybindings.keyup(key)
    @keybindings.enable 32, => @toggle()
    @keybindings.enable 27, => @stop()

  setup_cursorbindings: () ->
    # TODO mouse events should be handled though Signals
    onmousemove = (e) =>
      x = (e.pageX - @overlay_canvas.offsetLeft) / @settings.canvas.scale
      y = (e.pageY - @overlay_canvas.offsetTop) / @settings.canvas.scale
      @mousemove.dispatch x,y

    onmouseup = (e) =>
      x = (e.pageX - @overlay_canvas.offsetLeft) / @settings.canvas.scale
      y = (e.pageY - @overlay_canvas.offsetTop) / @settings.canvas.scale
      @mouseup.dispatch x,y

    onmousedown = (e) =>
      x = (e.pageX - @overlay_canvas.offsetLeft) / @settings.canvas.scale
      y = (e.pageY - @overlay_canvas.offsetTop) / @settings.canvas.scale
      @mousedown.dispatch x,y

    @overlay_canvas.addEventListener("mousedown"  , onmousedown , false)
    @overlay_canvas.addEventListener("mouseup"    , onmouseup   , false)
    @overlay_canvas.addEventListener("mousemove"  , onmousemove , false)
    @overlay_canvas.addEventListener("mouseout"   , onmouseup   , false)

    @overlay_canvas.addEventListener("touchstart" , onmousedown , false)
    @overlay_canvas.addEventListener("touchend"   , onmouseup   , false)
    @overlay_canvas.addEventListener("touchmove"  , onmousemove , false)
