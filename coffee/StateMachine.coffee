# https://github.com/millermedeiros/js-signals/wiki/Examples
# http://codeincomplete.com/posts/2011/8/19/javascript_state_machine_v2/
Naubino.NaubMachine = class NaubMachine

  constructor: ->
    @graph = Naubino.graph
    @game = Naubino.game
    @fsm = @create_fsm()


  create_fsm: ->
    StateMachine.create {
      initial: 'menu',
      events:[
        {  name: 'play',      from: 'menu',     to: 'playing' }
        {  name: 'pause',     from: 'playing',  to: 'paused'  }
        {  name: 'play',      from: 'paused',   to: 'playing' }
        {  name: 'unpause',   from: 'paused',   to: 'playing' }
        {  name: 'win',       from: 'playing',  to: 'won'     }
        {  name: 'lose',      from: 'playing',  to: 'lost'    }
        {  name: 'exit',      from: 'playing',  to: 'menu'    }
        {  name: 'show_help', from: 'menu',     to: 'help'    }
        {  name: 'hide_help', from: 'help',     to: 'menu'    }
        {  name: 'retry',     from: 'lost',     to: 'playing' }
      ]
      callbacks:
        onenterplaying: (event, from, to) ->
          Naubino.game.start_timer()
          Naubino.menu.switch_to_playing()
          Naubino.rules.run()

        onleaveplaying: (event, from, to) ->

        onpaused: (event, from, to) ->
          Naubino.game.stop_timer()
          Naubino.menu.switch_to_paused()
          Naubino.rules.halt()

        onpause: (event, from, to) ->

        onunpause: (event, from, to) ->
          Naubino.game.start_timer()

        onexit: (event, from, to) ->
    }



