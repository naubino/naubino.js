########################################################
#     _   __            __    _                 _      #
#    / | / /___ ___  __/ /_  (_)___  ____      (_)____ #
#   /  |/ / __ `/ / / / __ \/ / __ \/ __ \    / / ___/ #
#  / /|  / /_/ / /_/ / /_/ / / / / / /_/ /   / (__  )  #
# /_/ |_/\__,_/\__,_/_.___/_/_/ /_/\____(_)_/ /____/   #
#                                        /___/         #
########################################################
# TODO questionable approach
window.onload = ->
  Naubino.constructor()

@Naubino = {
  VERSION : 'UNSTABLE MASTER BRANCH'
  constructor: () ->

    @graph = new @Graph()
    @colors = @Settings.colors.output
    @fsm = @create_fsm()
    @Signal = window.signals.Signal
    @add_signals()
    @add_generic_listeners()

    @init_dom()

    @setup_keybindings()
    @setup_cursorbindings()

    #TODO switch Rulesets via a statemachine
    #@rules = new @RuleSet()
    #@rules  = new @Tutorial()
    @rules = new @TestCase()
    #@menu_play.dispatch() #TODO remove this line
    
  print: ->
    @gamediv.insertAdjacentHTML("afterend","<img src=\"#{@game_canvas.toDataURL()}\"/>")

  init_dom: () ->
    @gamediv           = document.querySelector("#gamediv")
    @overlay_canvas    = document.querySelector("#overlay_canvas")
    @menu_canvas       = document.querySelector("#menu_canvas")
    @game_canvas       = document.querySelector("#game_canvas")
    @background_canvas = document.querySelector("#background_canvas")

    for canvas in  @gamediv.querySelectorAll("canvas")
      canvas.width = @Settings.canvas.width
      canvas.height = @Settings.canvas.height


    @gamediv.max-width     = @Settings.canvas.width

    @background = new @Background(@background_canvas)
    @game       = new @Game(@game_canvas, @graph)
    @menu       = new @Menu(@menu_canvas)
    @overlay    = new @Overlay(@overlay_canvas)

  create_fsm: ->
    StateMachine.create {
      initial: 'menu',
      target: this
      events:[
        {  name: 'play',      from: 'menu',     to: 'playing' }
        {  name: 'pause',     from: 'playing',  to: 'paused'  }
        {  name: 'play',      from: 'paused',   to: 'playing' }
        {  name: 'toggle',    from: 'playing',  to: 'paused'  }
        {  name: 'toggle',    from: 'paused',   to: 'playing' }
        {  name: 'win',       from: 'playing',  to: 'won'     }
        {  name: 'lose',      from: 'playing',  to: 'lost'    }
        {  name: 'exit',      from: 'playing',  to: 'menu'    }
        {  name: 'show_help', from: 'menu',     to: 'help'    }
        {  name: 'hide_help', from: 'help',     to: 'menu'    }
        {  name: 'retry',     from: 'lost',     to: 'playing' }
      ]
      callbacks:
        onenterplaying: (event, from, to) ->
          @game.start_timer()
          @menu.switch_to_playing()
          @rules.run()

        onleaveplaying: (event, from, to) ->

        onpaused: (event, from, to) ->
          @game.stop_timer()
          @menu.switch_to_paused()
          @rules.halt()

        onpause: (event, from, to) ->

        onunpause: (event, from, to) ->
          @game.start_timer()

        onexit: (event, from, to) ->
    }

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
    @menu_toggle     = new @Signal()
    @menu_exit       = new @Signal()
    @menu_help       = new @Signal()


# TODO: think about making the menu a statemachine too
  add_generic_listeners: ->
    @menu_pause.add =>
      @fsm.pause()
      console.log "menu: pause"
      @menu_pause.active = false
      @menu_play.active = true

    @menu_play.add =>
      @fsm.play()
      console.log "menu: play"
      @menu_pause.active = true
      @menu_play.active = false

    @menu_toggle.add =>
      @fsm.toggle()

    @menu_exit.add =>
      @fsm.exit()
      console.log "menu: exit"

    @menu_help.add =>
      @fsm.show_help()
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
    @keybindings.enable 32, => @menu_toggle.dispatch()


  setup_cursorbindings: () ->
    # TODO mouse events should be handled though Signals
    onmousemove = (e) =>
      @mousemove.dispatch e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    onmouseup = (e) =>
      @mouseup.dispatch e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    onmousedown = (e) =>
      @mousedown.dispatch e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    @overlay_canvas.addEventListener("mousedown"  , onmousedown , false)
    @overlay_canvas.addEventListener("mouseup"    , onmouseup   , false)
    @overlay_canvas.addEventListener("mousemove"  , onmousemove , false)
    @overlay_canvas.addEventListener("mouseout"   , onmouseup   , false)

    @overlay_canvas.addEventListener("touchstart" , onmousedown , false)
    @overlay_canvas.addEventListener("touchend"   , onmouseup   , false)
    @overlay_canvas.addEventListener("touchmove"  , onmousemove , false)
}
