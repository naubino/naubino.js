# https://github.com/millermedeiros/js-signals/wiki/Examples
Naubino.GameMode = class GameMode
  constructor: (@game ) ->
    @graph = @game.graph
    @world = @game.world
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
    @cycle_found = new @Signal()

  add_listeners: ->
    @naub_replaced.add(@game.graph.cycle_test)
    @cycle_found.add( (list) => @game.destroy_naubs list )

