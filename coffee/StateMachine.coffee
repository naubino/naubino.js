# https://github.com/millermedeiros/js-signals/wiki/Examples
Naubino.NaubMachine = class NaubMachine

  constructor: ->
    @graph = Naubino.graph
    @game = Naubino.game
    @Signal = window.signals.Signal
    @fsm = @create_fsm()

    @add_signals()
    @add_generic_listeners()
    @add_listeners()

  create_fsm: ->
    StateMachine.create {
      initial: 'menu',
      events:[
        {  name: 'play',      from: 'menu',     to: 'playing' }
        {  name: 'pause',     from: 'playing',  to: 'paused' }
        {  name: 'unpause',   from: 'paused',   to: 'playing' }
        {  name: 'win',       from: 'playing',  to: 'won' }
        {  name: 'lose',      from: 'playing',  to: 'lost' }
        {  name: 'exit',      from: 'playing',  to: 'menu' }
        {  name: 'show_help', from: 'menu',     to: 'help' }
        {  name: 'hide_help', from: 'help',     to: 'menu' }
        {  name: 'retry',     from: 'lost',     to: 'playing' }
      ]
      callbacks:
        onenterplaying: (event, from, to) ->
          Naubino.game.create_some_naubs 3
          Naubino.game.start_timer()
          Naubino.menu.set_playing_state()

        onleaveplaying: (event, from, to) ->
          Naubino.menu.set_menu_state()

        onpaused: (event, from, to) ->
          Naubino.game.stop_timer()

        onpause: (event, from, to) ->

        onunpause: (event, from, to) ->
          Naubino.game.start_timer()

        onexit: (event, from, to) ->
    }

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

    # menu
    @menu_pause  = new @Signal()
    @menu_play   = new @Signal()
    @menu_exit   = new @Signal()
    @menu_help   = new @Signal()


  add_generic_listeners: ->
    @menu_pause.add =>
      console.log "menu: pause"
      @fsm.pause()

    @menu_play.add =>
      console.log "menu: play"
      @fsm.play()

    @menu_exit.add =>
      console.log "menu: exit"
      @fsm.exit()

    @menu_help.add =>
      console.log "menu: help"
      @fsm.help()

  add_listeners: ->

