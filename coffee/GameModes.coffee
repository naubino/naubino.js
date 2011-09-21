# https://github.com/millermedeiros/js-signals/wiki/Examples
Naubino.State = class State
  constructor: ->
    @graph = Naubino.graph
    @world = Naubino.world
    @Signal = window.signals.Signal

    @add_signals()
    @add_generic_listeners()
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
    @game_show_help= new @Signal()
    @game_ended = new @Signal()
    @game_levelup = new @Signal()

  add_generic_listeners: ->
    @game_paused.add ->
      Naubino.game.stop_timer()
      console.log "game_paused"
    @game_started.add ->
      Naubino.game.start_timer()
      console.log "game_started"
    @game_show_help.add ->
      console.log "this person needs help"

  add_listeners: ->

  enter_state: ->
  leave_state: ->


Naubino.MenuState = class MenuState extends Naubino.State
  constructor: ->
    super()




Naubino.PlayingState = class PlayingState extends Naubino.State
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


  enter_state: ->
    Naubino.menu.set_playing_state()
    @game.create_some_naubs(6)
    @game.points = 0

  leave_state: ->
    let_me_go = confirm "WARNING!!\n Your points are not being saved yet!\n Write them down!"
    Naubino.menu.set_menu_state() if let_me_go
    return let_me_go



Naubino.StateMachine = class StateMachine
  constructor: ->
    @states = {
      menu: new MenuState()
      playing: new PlayingState()
    }

    Naubino.state = @states.menu

  change_state: ->


