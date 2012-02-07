
window.onload = ->
  Naubino.constructor()

@Naubino = {
  VERSION:  'tutorial branch'
  constructor: () ->


    @graph = new @Graph()
    @colors = @Settings.colors.output
    @state_machine = new @NaubMachine()
    @Signal = window.signals.Signal
    @add_signals()
    @add_generic_listeners()

    @init_dom()

    @setup_keybindings()
    @setup_cursorbindings()

    #TODO switch Rulesets via a statemachine
    #@rules = new @RuleSet()
    @rules  = new @Tutorial()
    #@rules = new @TestCase()
    #@menu_play.dispatch() #TODO remove this line
    


  init_dom: () ->
    @gamediv           = document.getElementById("gamediv")
    @overlay_canvas    = document.getElementById("overlay_canvas")
    @menu_canvas       = document.getElementById("menu_canvas")
    @game_canvas       = document.getElementById("game_canvas")
    @background_canvas = document.getElementById("background_canvas")

    @overlay_canvas.width  = @menu_canvas.width     = @game_canvas.width  = @background_canvas.width  = @Settings.canvas.width
    @overlay_canvas.height = @menu_canvas.height    = @game_canvas.height = @background_canvas.height = @Settings.canvas.height
    @gamediv.max-width     = @Settings.canvas.width
    @gamediv.style.border  = "2px"

    @background = new @Background(@background_canvas)
    @game       = new @Game(@game_canvas, @graph)
    @menu       = new @Menu(@menu_canvas)
    @overlay    = new @Overlay(@overlay_canvas)

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

    # gameplay
    @naub_replaced   = new @Signal()
    @naub_joined     = new @Signal()
    @naub_destroyed  = new @Signal()
    @cycle_found     = new @Signal()
    @naub_focused    = new @Signal()
    @naub_unfocused  = new @Signal()


    # menu
    @menu_focus      = new @Signal()
    @menu_blur       = new @Signal()
    @menu_pause      = new @Signal()
    @menu_play       = new @Signal()
    @menu_exit       = new @Signal()
    @menu_help       = new @Signal()


  add_generic_listeners: ->
    @menu_pause.add =>
      @state_machine.fsm.pause()
      console.log "menu: pause"
      @menu_pause.active = false
      @menu_play.active = true

    @menu_play.add =>
      @state_machine.fsm.play()
      console.log "menu: play"
      @menu_pause.active = true
      @menu_play.active = false

    @menu_exit.add =>
      @state_machine.fsm.exit()
      console.log "menu: exit"

    @menu_help.add =>
      @state_machine.fsm.show_help()
      console.log "menu: help"
    @menu_focus.add =>
      @menu.hovering = true

    @menu_blur.add =>
      @menu.hovering = false

  add_listeners: ->

  setup_keybindings: () ->
    @keybindings = new @KeyBindings()
    window.onkeydown = (key) => @keybindings.keydown(key)
    window.onkeyup = (key) => @keybindings.keyup(key)
    @keybindings.enable 32, => @menu_pause.dispatch()


  setup_cursorbindings: () ->
    # TODO mouse events must go solely through mode
    onmousemove = (e) =>
      #@mousemove.dispatch(e)
      @menu.move_pointer e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop
      @game.move_pointer e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    onmouseup = (e) =>
      @mouseup.dispatch(e)
      @game.unfocus e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    onmousedown = (e) =>
      @mousedown.dispatch(e)
      @menu.click e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop
      @game.click e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    @overlay_canvas.addEventListener("mousedown"  , onmousedown , false)
    @overlay_canvas.addEventListener("mouseup"    , onmouseup   , false)
    @overlay_canvas.addEventListener("mousemove"  , onmousemove , false)
    @overlay_canvas.addEventListener("mouseout"   , onmouseup   , false)

    @overlay_canvas.addEventListener("touchstart" , onmousedown , false)
    @overlay_canvas.addEventListener("touchend"   , onmouseup   , false)
    @overlay_canvas.addEventListener("touchmove"  , onmousemove , false)
}
