###
     _   __            __    _                 _
    / | / /___ ___  __/ /_  (_)___  ____      (_)____
   /  |/ / __ `/ / / / __ \/ / __ \/ __ \    / / ___/
  / /|  / /_/ / /_/ / /_/ / / / / / /_/ /   / (__  )
 /_/ |_/\__,_/\__,_/_.___/_/_/ /_/\____(_)_/ /____/
                                        /___/
###

import {Input} from './Input'
import {Settings} from './config/Settings'
import {Viewport} from './Viewport'
import {GameLoop} from './GameLoop'
import {Session} from './Session'
import {Background} from './ui/Background'
import {Menu} from './ui/Menu'
import {Overlay} from './ui/Overlay'
import {Game} from './game/Game'
import {StandardMode} from './modes/standard/StandardMode'
import {Util} from './core/Util'
import {Signal} from './core/Signal'
import {Events} from './Events'
import {Audio} from './Audio'

export class Naubino

  constructor: (@mode = new StandardMode) ->

    @name = "Naubino (unstable master)"
    @settings = Settings

    @Signal = Signal
    @events = new Events


    @load_highscores()
    @audio = new Audio

  load_highscores: ->
    string = localStorage.getItem("naubino_hiscore")
    @scores =
      if string
        JSON.parse string
      else [ {name:"nobody", points: 0, time: 0, naubs: 0, level: 0 } ]

  set_score: -> @temp_score = @game.score_snapshot()

  finish_run: (score) ->
    @temp_score = score
    return unless score? and score.points > 0
    name = prompt "Enter your name for the highscore"
    @store_score name if name?

  store_score: (name = 'nobody')->
    @temp_score.name = name
    @temp_score.date = Date.now()
    @scores.push @temp_score
    string = JSON.stringify @scores
    localStorage.setItem("naubino_hiscore",string)



  setup: ->
    @setup_dom()
    @setup_components()
    @setup_session()
    @setup_input()
    @init()
    @play() if @mode.auto_start
    @start_loop()
    console.timeEnd("loading")

  color_scheme: -> @settings.colors[@settings.color]
  colors: -> @color_scheme().naubs
  recolor: -> @game.for_each (naub) -> naub.recolor()

  # pushes the active scheme's background onto the page so CSS (e.g.
  # #background_canvas) can pick it up via --canvas-background-color.
  # an inline custom property wins over whatever the prefers-color-scheme
  # media query would otherwise set on :root.
  apply_color_scheme: ->
    color = Util.color_to_rgba @color_scheme().background()
    document.documentElement.style.setProperty '--canvas-background-color', color
  print: -> @viewport.container.insertAdjacentHTML("afterend","<img src=\"#{@game.canvas.toDataURL()}\"/>")

  setup_dom: ->
    container = document.querySelector '#gamediv'
    form = document.querySelector 'form'
    @viewport = new Viewport container, @settings.canvas, {
      centered_elements: if form? then [form] else []
    }

  setup_components: ->
    canvases = @viewport.canvases
    @background = new Background canvases.background_canvas
    @menu = new Menu canvases.menu_canvas, @events
    @overlay = new Overlay canvases.overlay_canvas
    @game = new Game canvases.game_canvas, @mode, @events
    @layers = [@background, @game, @menu, @overlay]

    @view_subscriptions = [
      @events.game.overflow_warning.add (severity) => @background.warn_overflow severity
      @events.game.basket_changed.add => @background.draw()
    ]
    @background.set_basket_size_provider => @game.basket?.basket_size()
    @viewport.set_layers @layers, [@background, @game, @menu]
    @viewport.on_resize = (width, height) => @game.resize width, height
    @loop = new GameLoop @layers

  setup_session: ->
    @session = new Session {
      game: @game
      menu: @menu
      overlay: @overlay
      background: @background
      transitions: @settings.events
      events: @events
      name: @name
      on_finished: (score) => @finish_run score
    }


  init:   (args...) -> @session.init args...
  play:   (args...) -> @session.play args...
  pause:  (args...) -> @session.pause args...
  stop:   (args...) -> @session.stop args...
  loose:  (args...) -> @session.loose args...
  toggle: -> @session.toggle()
  can:    (event) -> @session.can event

  start_loop: -> @loop.start()
  stop_loop: -> @loop.stop()

  dispose: ->
    @input?.unbind()
    @session?.dispose()
    @game?.dispose()
    @menu?.dispose()
    unsubscribe() for unsubscribe in (@view_subscriptions ? [])
    @view_subscriptions = []
    @loop?.stop()

  center: -> @viewport.center()
  scale_to: (scale) -> @viewport.scale_to scale
  demaximize: -> @viewport.demaximize()
  available_size: -> @viewport.available_size()
  maximize: -> @viewport.maximize()
  fit_field_to_viewport: -> @viewport.fit_field_to_viewport()
  resize_field: (width, height) -> @viewport.resize_field width, height
  stretch: (width) -> @viewport.stretch width


  list_states: ->
    for o in [@session, @menu, @game, @overlay, @background]
      switch o.current
        when 'playing' then console.info o.name, o.current, o.fps, o.step_rate
        when 'paused'  then console.warn o.name, o.current, o.fps, o.step_rate
        when 'stopped' then console.warn o.name, o.current, o.fps, o.step_rate
        else console.error o.name, o.current


  setup_input: ->
    @input = new Input {
      canvas: @viewport.canvases.overlay_canvas
      viewport: @viewport
      events: @events
    }
    @input.bind()
