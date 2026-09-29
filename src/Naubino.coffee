###
     _   __            __    _                 _
    / | / /___ ___  __/ /_  (_)___  ____      (_)____
   /  |/ / __ `/ / / / __ \/ / __ \/ __ \    / / ___/
  / /|  / /_/ / /_/ / /_/ / / / / / /_/ /   / (__  )
 /_/ |_/\__,_/\__,_/_.___/_/_/ /_/\____(_)_/ /____/
                                        /___/
###

import {KeyBindings} from './Keybindings'
import {Settings} from './Settings'
import {LayerManager} from './LayerManager'

export class Naubino extends LayerManager

  constructor: () ->
    super()
    @name = "Naubino (unstable master)"
    @settings = Settings
    @Signal = window.signals.Signal
    @setup_signals()
    @add_listeners()
    @scale = 1 # will be changed by fullscreen
    @load_highscores()
    #@audio = new Audio

  load_highscores: ->
    string = localStorage.getItem("naubino_hiscore")
    @scores =
      if string
        JSON.parse string
      else [ {name:"nobody", points: 0, time: 0, naubs: 0, level: 0 } ]

  set_score: ->
    @temp_score = {
        name:"nobody"
        points: @game.points
        time: @game.duration
        naubs: @game.ex_naubs
        game_version: @game.version
        level: @game.level
    }

  store_score: (name = 'nobody')->
    @temp_score.name = name
    @temp_score.date = Date.now()
    @scores.push @temp_score
    string = JSON.stringify @scores
    localStorage.setItem("naubino_hiscore",string)



  setup: ->
    @setup_dom()
    @setup_layers()
    @setup_keybindings()
    @setup_cursorbindings()
    @setup_fsm()
    @init()
    console.timeEnd("loading")

  colors: -> @settings.colors[@settings.color]
  recolor: -> @game.for_each (naub) -> naub.recolor()
  print: -> @gamediv.insertAdjacentHTML("afterend","<img src=\"#{@game_canvas.toDataURL()}\"/>")

  setup_dom: () ->
    @gamediv = document.querySelector("#gamediv")
    @gamediv.max-width = @settings.canvas.width
    @canvases = {}
    { width, height } = @settings.canvas
    for name in 'background game menu overlay'.split ' '
      name += '_canvas'
      canvas = document.createElement 'canvas'
      canvas.width = width
      canvas.height = height
      canvas.setAttribute 'id', name
      @[name] = canvas
      @gamediv.appendChild canvas
      @canvases[name] = canvas

  # Signals connect everything else that does not react to events

  setup_signals: ->
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

  setup_keybindings: () ->
    @keybindings = new KeyBindings()
    window.onkeydown = (key) => @keybindings.keydown(key)
    window.onkeyup = (key) => @keybindings.keyup(key)
    @keybindings.enable 32, => @toggle()
    @keybindings.enable 27, => @stop()

  setup_cursorbindings: () ->
    # TODO mouse events should be handled though Signals
    # touch events carry coordinates in changedTouches, not on the event itself
    game_coords = (e) =>
      point = e.changedTouches?[0] ? e
      rect  = @overlay_canvas.getBoundingClientRect()
      x = (point.clientX - rect.left - @overlay_canvas.clientLeft) / @scale
      y = (point.clientY - rect.top  - @overlay_canvas.clientTop)  / @scale
      e.preventDefault() if e.changedTouches? # no emulated mouse events after touch
      [x, y]

    onmousemove = (e) => @mousemove.dispatch game_coords(e)...
    onmouseup   = (e) => @mouseup.dispatch   game_coords(e)...
    onmousedown = (e) => @mousedown.dispatch game_coords(e)...

    @overlay_canvas.addEventListener("mousedown"  , onmousedown , false)
    @overlay_canvas.addEventListener("mouseup"    , onmouseup   , false)
    @overlay_canvas.addEventListener("mousemove"  , onmousemove , false)
    @overlay_canvas.addEventListener("mouseout"   , onmouseup   , false)

    # two finger tap toggles play/pause
    gesture = null

    ontouchstart = (e) =>
      if e.touches.length is 2
        onmouseup e # let go of whatever the first finger grabbed
        gesture = { start: Date.now() }
      else if gesture?
        e.preventDefault()
      else
        onmousedown e

    ontouchmove = (e) =>
      if gesture? then e.preventDefault() else onmousemove e

    ontouchend = (e) =>
      if gesture?
        e.preventDefault()
        if e.touches.length is 0
          @toggle() if e.type is "touchend" and Date.now() - gesture.start < 400
          gesture = null
      else
        onmouseup e

    @overlay_canvas.addEventListener("touchstart" , ontouchstart , false)
    @overlay_canvas.addEventListener("touchend"   , ontouchend   , false)
    @overlay_canvas.addEventListener("touchcancel", ontouchend   , false)
    @overlay_canvas.addEventListener("touchmove"  , ontouchmove  , false)
