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
    @create_fsm()
    @Signal = window.signals.Signal
    @add_signals()
    @add_listeners()

    @init_dom()
    @init_layers()

    @setup_keybindings()
    @setup_cursorbindings()

    #TODO switch Rulesets via a statemachine
    @rules = new @RuleSet()
    @rules.init()
    #@rules  = new @Tutorial()
    #@rules = new @TestCase()
    #@menu_play.dispatch() #TODO remove this line
    
  print: -> @gamediv.insertAdjacentHTML("afterend","<img src=\"#{@game_canvas.toDataURL()}\"/>")

  init_dom: () ->
    @gamediv           = document.querySelector("#gamediv")
    @overlay_canvas    = document.querySelector("#overlay_canvas")
    @menu_canvas       = document.querySelector("#menu_canvas")
    @game_canvas       = document.querySelector("#game_canvas")
    @background_canvas = document.querySelector("#background_canvas")

    for canvas in  @gamediv.querySelectorAll("canvas")
      canvas.width = @Settings.canvas.width
      canvas.height = @Settings.canvas.height

  init_layers: ->
    @gamediv.max-width     = @Settings.canvas.width

    @background = new @Background(@background_canvas)
    @game       = new @Game(@game_canvas, @graph)
    @menu       = new @Menu(@menu_canvas)
    @overlay    = new @Overlay(@overlay_canvas)
    @menu.init()
    @game.init()
    @background.init()
    @overlay.init()

  ###
  Everything has to have state
  ###
  create_fsm: ->
    StateMachine.create {
      target: this
      initial: {state : 'stopped' , event: 'init'}
      events:[ # TODO stil simplified
        { name: 'init',   from: 'stopped',  to: 'paused'  }
        { name: 'play',   from: 'paused',   to: 'playing' }
        { name: 'pause',  from: 'playing',  to: 'paused'  }
        { name: 'toggle', from: ['playing','paused']     }
      ]
    }

  list_states: ->
    console.log "menu:", @menu.current
    console.log "game:", @game.current
    console.log "background:", @background.current
    console.log "overlay:", @overlay.current
    console.log "rules:", @rules.current

  onchangestate: (e,f,t)->
    console.warn "Naubino recived #{e}: #{f} -> #{t}"
    #@list_states()
    return true

  onbeforeplay: (event, from, to) ->
    @menu.play()
    @rules.play()

  ontoggle: (event, from, to) ->
    console.log "toggled", from

  onbeforepause: (event, from, to) ->
    console.warn from
    unless from == "init"
      @rules.pause()

  onenterplaying: ->
    console.timeEnd("init_play")
    #if any failes return false ( cancels transition )

  onpause: (event, from, to) ->

  onexit: (event, from, to) ->

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

    # gameplay
    @naub_replaced   = new @Signal()
    @naub_joined     = new @Signal()
    @naub_destroyed  = new @Signal()
    @cycle_found     = new @Signal()
    @naub_focused    = new @Signal()
    @naub_unfocused  = new @Signal()

    # menu
    @menu_button     = new @Signal()
    @menu_focus      = new @Signal()
    @menu_blur       = new @Signal()


  add_listeners: ->
    @menu_focus.add =>
      @menu.hovering = @menu_button.active = true

    @menu_blur.add =>
      @menu.hovering = @menu_button.active = false

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
