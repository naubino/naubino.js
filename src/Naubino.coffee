###
     _   __            __    _                 _
    / | / /___ ___  __/ /_  (_)___  ____      (_)____
   /  |/ / __ `/ / / / __ \/ / __ \/ __ \    / / ___/
  / /|  / /_/ / /_/ / /_/ / / / / / /_/ /   / (__  )
 /_/ |_/\__,_/\__,_/_.___/_/_/ /_/\____(_)_/ /____/
                                        /___/
###

import {KeyBindings} from './KeyBindings'
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
    @temp_score =
      name: "nobody"
      points: @game.points
      time: @game.duration
      naubs: @game.ex_naubs
      game_version: @game.version
      level: @game.level
    

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

  ###
  Signals connect everything else that does not react to events
  ###

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
    @keybindings.enable 77, => @game.spam()
    @keybindings.enable 77, => @game.spam()

  setup_cursorbindings: () ->
    # TODO mouse events should be handled though Signals
    onmousemove = (e) =>
      x = (e.pageX - @overlay_canvas.offsetLeft) / @scale
      y = (e.pageY - @overlay_canvas.offsetTop) /  @scale
      @mousemove.dispatch x,y

    onmouseup = (e) =>
      x = (e.pageX - @overlay_canvas.offsetLeft) / @scale
      y = (e.pageY - @overlay_canvas.offsetTop) /  @scale
      @mouseup.dispatch x,y

    onmousedown = (e) =>
      x = (e.pageX - @overlay_canvas.offsetLeft) / @scale
      y = (e.pageY - @overlay_canvas.offsetTop) /  @scale
      @mousedown.dispatch x,y

    @overlay_canvas.addEventListener("mousedown"  , onmousedown , false)
    @overlay_canvas.addEventListener("mouseup"    , onmouseup   , false)
    @overlay_canvas.addEventListener("mousemove"  , onmousemove , false)
    @overlay_canvas.addEventListener("mouseout"   , onmouseup   , false)

    @overlay_canvas.addEventListener("touchstart" , onmousedown , false)
    @overlay_canvas.addEventListener("touchend"   , onmouseup   , false)
    @overlay_canvas.addEventListener("touchmove"  , onmousemove , false)
