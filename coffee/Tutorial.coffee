Naubino.Tutorial = class Tutorial extends Naubino.RuleSet
  @name = "Tutorial"
  constructor: ->
    super()
    

# states: -> welcome -> show naubs -> move naubs -> join naubs -> form circle -> success

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
          console.log "Tutorial.fsm.onwelcome"
          Naubino.mousedown.active = false
          Naubino.mousedown.addOnce =>
            @fsm.click()
            console.log "Tutorial.fsm.click"

          Naubino.overlay.fade_in_message("Tutorial", null, 25)
          setTimeout ->
            Naubino.overlay.fade_in_message("\n\nclick to continue", null ,12)
            Naubino.mousedown.active = true
          ,1000


        onleavewelcome: =>
          console.log "Tutorial.fsm.onleavewelcome"
          Naubino.overlay.fade_out =>
            @fsm.transition()
            Naubino.overlay.clear_objs()
            Naubino.overlay.show()
          false

        onbeforeshow_naubs: ->
          console.log "Tutorial.fsm.onbeforeshow_naubs"

        onshow_naubs: ->
          console.log "Tutorial.fsm.onshow_naubs"
          Naubino.naub_replaced.addOnce -> console.log 'joined'
          Naubino.game.create_matching_naubs(2)
          Naubino.game.start_timer()
          weightless = -> Naubino.game.gravity = off
          m1 = => Naubino.overlay.fade_in_and_out_message("These are Naubs", 2000, m2, 25)
          m2 = => Naubino.overlay.fade_in_message("Try to move them around", null, 25)
          setTimeout weightless, 4000
          setTimeout m1, 2000
          Naubino.naub_unfocused.add (naub) -> console.log "unfocused" + naub.color_id
      }
    }

  run: ->
