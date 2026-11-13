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

import {Menu} from './ui/Menu'
import {Overlay} from './ui/Overlay'
import {Game} from './game/Game'
import {StandardMode} from './modes/standard/StandardMode'
import {Util} from './core/Util'
import {Signal} from './core/Signal'
import {Events} from './Events'
import {Audio} from './Audio'

export class Naubino
  name: "Naubino (#{import.meta.env.MODE})"
  settings: Settings
  Signal: Signal

  constructor: (@mode = new StandardMode, @root_element_id) ->
    @events = new Events
    @load_highscores()
    @audio = new Audio(@settings)

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
    @setup_input()
    @start_game @mode
    @play() if @mode.auto_start
    @start_loop()
    console.timeEnd("loading")

  color_scheme: -> @settings.colors[@settings.color]
  colors: ->
    @color_scheme()

  recolor: -> @game.for_each (naub) -> naub.recolor()

  # pushes the active scheme's background onto the page so CSS can pick it up
  # via --canvas-background-color.
  # an inline custom property wins over whatever the prefers-color-scheme
  # media query would otherwise set on :root.
  apply_color_scheme: ->
    color = Util.color_to_rgba @color_scheme().background()
    document.documentElement.style.setProperty '--canvas-background-color', color
    @recolor()

  print: -> @viewport.container.insertAdjacentHTML("afterend","<img src=\"#{@game.canvas.toDataURL()}\"/>")

  setup_dom: ->
    container = document.querySelector @root_element_id
    form = document.querySelector 'form'
    @viewport = new Viewport container, @settings.canvas, {
      centered_elements: if form? then [form] else []
      events: @events
    }

  setup_components: ->
    @menu_lease = @viewport.lease 2, 'canvas-menu'
    @overlay_lease = @viewport.lease 3, 'canvas-overlay'
    @menu = new Menu @menu_lease.canvas, @events, @viewport
    @overlay = new Overlay @overlay_lease.canvas, @viewport
    @layers = [@menu, @overlay]
    @menu.init()
    @overlay.init()
    @viewport.set_layers @layers, [@menu]
    @loop = new GameLoop @layers

  attach: (game) ->
    subscriptions = [
      game.events.score_changed.add (points) =>
        @menu.score = points
        @menu.draw()
      game.events.level_changed.add (level) =>
        @overlay.fade_in_and_out_message "Level #{level}" if level > 0
      game.events.chain_bonus.add (points) => @overlay.fly_in_and_out_message "\n\nChain Bonus #{points}"
      game.events.overflow_warning.add (severity) -> game.background.warn_overflow severity
      game.events.basket_changed.add (size) ->
        game.background.basket_size = size
        game.background.draw()
      game.events.state_changed.add (state) =>
        @menu.check_game_state state
        switch state
          when 'playing'
            @overlay.play() if @overlay.can 'play'
            game.background.play() if game.background.can 'play'
          when 'paused'
            @overlay.pause() if @overlay.can 'pause'
            game.background.pause() if game.background.can 'pause'
          when 'finished'
            @overlay.stop() if @overlay.can 'stop'
            game.background.stop() if game.background.can 'stop'
      game.events.lost.add (reason) => @overlay.warning reason
      game.events.finished.add (snapshot) =>
        @finish_run snapshot
        @start_game @mode
      game.events.naub_joined.add @audio.random_blub
      game.events.naub_replaced.add @audio.random_blub
      game.events.naub_destroyed.add @audio.random_blub
    ]
    -> unsubscribe() for unsubscribe in subscriptions

  start_game: (mode = @mode) ->
    @detach_game?()
    @detach_game = null
    @game?.dispose()
    @overlay.stop() if @overlay.can 'stop'
    @mode = mode
    @game = new Game @viewport, @mode, @events
    @layers = @game.layers.concat [@menu, @overlay]
    @viewport.set_layers @layers, @game.layers.concat [@menu]
    @viewport.on_resize = (width, height) => @game.resize width, height
    @loop.game = @game
    @detach_game = @attach @game
    @game.publish_snapshot()
    @menu.check_game_state @game.current
    @game

  # state machine forwarding

  play:   (args...) -> @game.play args...
  pause:  (args...) -> @game.pause args...
  stop:   (args...) -> @game.stop args...
  loose:  (args...) -> @game.loose args...
  toggle: (args...)-> @game.toggle(args...)
  can:    (event) -> @game.can event

  start_loop: -> @loop.start()
  stop_loop: -> @loop.stop()

  dispose: ->
    @input?.unbind()
    @loop?.stop()
    @detach_game?()
    @detach_game = null
    @game?.dispose()
    @menu?.dispose()
    @viewport?.dispose()

  center: -> @viewport.center()
  scale_to: (scale) -> @viewport.scale_to scale
  demaximize: -> @viewport.demaximize()
  available_size: -> @viewport.available_size()
  maximize: -> @viewport.maximize()
  fit_field_to_viewport: -> @viewport.fit_field_to_viewport()
  resize_field: (width, height) -> @viewport.resize_field width, height
  stretch: (width) -> @viewport.stretch width


  list_states: ->
    for o in [@menu, @game, @overlay, @game?.background]
      switch o.current
        when 'playing' then console.info o.name, o.current, o.fps, o.step_rate
        when 'paused'  then console.warn o.name, o.current, o.fps, o.step_rate
        when 'stopped' then console.warn o.name, o.current, o.fps, o.step_rate
        else console.error o.name, o.current


  setup_input: ->
    @input = new Input {@events}
    @input.bind()
