# https://github.com/millermedeiros/js-signals/wiki/Examples
Naubino.State = class State
  constructor: ->
    @graph = Naubino.graph
    @world = Naubino.world
    @Signal = window.signals.Signal

    @add_signals()
    @add_listeners()

  add_signals: ->
    
    # user interface
    @mousedown  = new @Signal()
    @mouseup = new @Signal()
    @mousemove = new @Signal()
    @keydown = new @Signal()
    @keyup = new @Signal()
    @touchstart = new @Signal()
    @touchend = new @Signal()
    @touchmove = new @Signal()

    # gameplay
    @naub_replaced = new @Signal()
    @naub_destroyed = new @Signal()
    @cycle_found = new @Signal()

    # states
    @game_started = new @Signal()
    @game_paused = new @Signal()
    @game_ended = new @Signal()
    @game_levelup = new @Signal()

  enter_state: =>
  leave_state: =>
  change_state: (next_state) ->
    @leave_state()
    next_state.enter_state()

Naubino.Playing = class PlayingState extends Naubino.State
  constructor: ->
    super()
    

  add_listeners: ->
    @naub_replaced.add(Naubino.graph.cycle_test)
    @cycle_found.add(
      (list) =>
        console.log list
        Naubino.game.destroy_naubs list
        #Naubino.game.pause()
    )
    @naub_destroyed.add(()->Naubino.game.points++)


Naubino.StateMachine = StateMachine.create {
  initial: 'menu'
  events: [
    {name: 'play', from: 'menu', to 'game'}
    {name: 'pause', from: 'game', to 'paused'}
    {name: 'unpause', from: 'paused', to 'game'}
    {name: 'quit', from: 'game', to 'menu'}
    {name: 'highscore', from: 'menu', to 'highscore'}
  ]

}
