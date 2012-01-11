Naubino.Tutorial = class Tutorial extends Naubino.RuleSet
  @name = "Tutorial"
  constructor: ->
    super()
    

  ###
   states: -> welcome
   -> show naubs
       "Thes are Naubs"
       "Try Moving the Around"
       "Very Good"
   -> join naubs
       "Naubs can be joined if they have the same color..."
       "Now join two naubs by push one into the other"
   -> form circle
   -> success
  ###

  configure: ->
    super()
    Naubino.menu_focus.active = false
    Naubino.game.joining_allowed = no
    StateMachine.create {
      target: this
      initial: 'welcome'
      events: [
        { name: 'click',  from: 'welcome',      to: 'show_naubs'  }
        { name: 'shown',  from: 'show_naubs',   to: 'move_naubs'  }
        { name: 'moved',  from: 'move_naubs',   to: 'join_naubs'  }
        { name: 'joined', from: 'join_naubs',   to: 'close_circle'}
        { name: 'click',  from: 'close_circle', to: 'success'     }
      ]
    }
    console.log @current

  ### Each lesson:
   # [sets preconditions]
   # [adds listeners
   # gives instructions
   # [unsets preconditions]
  ###


  onwelcome: (e, f, t) ->
    # set preconditions
    # add listeners
    Naubino.mousedown.active = false
    Naubino.mousedown.addOnce =>
      @click()

   # give instructions
    Naubino.overlay.fade_in_message("Tutorial", null, 25)
    setTimeout ->
      Naubino.overlay.fade_in_message("\n\nclick to continue", null ,12)
      Naubino.mousedown.active = true
    ,1000


  # fade out and then change state
  onleavewelcome: ->
    Naubino.overlay.fade_out_messages =>
      @transition()
    false

  onbeforeshow_naubs: ->
    console.log "onbeforeshow_naubs really has been called"

  onshow_naubs: =>
   # [sets preconditions]
   # adds listeners
    Naubino.game.create_matching_naubs(2)
    Naubino.game.start_timer()
    weightless = -> Naubino.game.gravity = off

   # gives instructions
    m1 = => Naubino.overlay.fade_in_and_out_message(["These are Naubs", 2000], m2, 25)
    m2 = => Naubino.overlay.fade_in_message("Try to move them around!", m3, 25)
    m3 = => @shown()
    setTimeout weightless, 4000
    setTimeout m1, 2000

  onmove_naubs: =>
    # remember a naubs original position
    binding1 = Naubino.naub_focused.add (naub) =>
      naub.old_pos = naub.physics.pos.Copy()

    # compare it with the new position
    binding2 = Naubino.naub_unfocused.add (naub) =>
      new_pos = naub.physics.pos.Copy()
      new_pos.Subtract naub.old_pos
      dragged_distance = new_pos.Length()
      if dragged_distance > 180
        # removing listeners
        binding1.detach()
        binding2.detach()
        @moved()


  # fade out and then change state
  onleavemove_naubs: =>
    Naubino.overlay.fade_out_messages =>
      @transition()
    false


  onjoin_naubs: =>
    console.log "very good"
    Naubino.overlay.fade_in_message("Very Good...", null, 25)
    Naubino.naub_replaced.addOnce -> console.log 'joined'


