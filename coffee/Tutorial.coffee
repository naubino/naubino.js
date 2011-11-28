Naubino.Tutorial = class Tutorial extends Naubino.RuleSet
  @name = "Tutorial"
  constructor: ->
    super()
    

# states:
# welcome
# show naubs
# move naubs
# join naubs
# form circle
# success




  configure: ->
    super()
    Naubino.menu_focus.active = false
    @fsm = StateMachine.create {
      initial: 'welcome'
      events: [
        { name: 'click',  from: 'welcome',      to: 'show_naubs'  }
        { name: 'timer',  from: 'show_naubs',   to: 'move_naubs'  }
        { name: 'moved',  from: 'move_naubs',   to: 'join_naubs'  }
        { name: 'joined', from: 'join_naubs',   to: 'close_circle'}
        { name: 'click',  from: 'close_circle', to: 'success'     }
      ]

      callbacks: {
        onwelcome: =>
          Naubino.mousedown.active = false
          Naubino.mousedown.addOnce =>
            @fsm.click()
            console.log "Tutorial.fsm.click"

          Naubino.overlay.fade_in_message("Welcome to Naubino", 25)
          setTimeout ->
            Naubino.overlay.message("\n\nclick to continue", 12)
            Naubino.mousedown.active = true
          ,1000


        onleavewelcome: =>
          console.log "Tutorial.fsm.onbeforeshow_naubs"
          Naubino.overlay.fade_out => @fsm.transition()
          false


        onshow_naubs: ->
          Naubino.game.create_matching_naubs(2)
          Naubino.game.start_timer()
          weightless = -> Naubino.game.gravity = off
          setTimeout(weightless, 4000)
          setTimeout ->
            Naubino.overlay.fade_in_message("These are Naubs", 25)
          ,3000
      }
    }

  run: ->
