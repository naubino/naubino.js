# https://github.com/millermedeiros/js-signals/wiki/Examples
Naubino.GameMode = class GameMode
  constructor: () ->
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
    @game_paused = new @Signal()


  add_listeners: ->
    @naub_replaced.add(Naubino.graph.cycle_test)
    @cycle_found.add(
      (list) =>
        console.log list
        Naubino.game.destroy_naubs list
        #Naubino.game.pause()
    )
    @naub_destroyed.add(()->Naubino.game.points++)


  enter_state: =>
  leave_state: =>
  change_state: (next_state) ->
    @leave_state()
    next_state.enter_state()
