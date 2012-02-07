Naubino.Tutorial = class Tutorial extends Naubino.RuleSet
  @name = "Tutorial"

  ###
  # Lesson 1
  #   Naubs can be moved
  #   Naubs can be joined
  # Lesson 2
  #   Cycles dissolve
  # vvvv TODO vvvv
  #   Single Naubs can be attached to any color TODO: modify create_matching_naubs accordingly
  # Lesson 3
  #   Naubs keep bein generated
  #   Too many Naubs can kill you
  ###

  configure: ->
    super()
    @font_size = 24
    Naubino.menu_focus.active = false
    Naubino.game.joining_allowed = no

    StateMachine.create {
      target: this
      initial: 'welcome'
      events: [
        { name: 'click',  from: 'welcome',      to: 'lesson_show'  }
        { name: 'shown',  from: 'lesson_show',  to: 'lesson_move'  }
        { name: 'moved',  from: 'lesson_move',  to: 'lesson_join'  }
        { name: 'joined', from: 'lesson_join',  to: 'lesson_cycle' }
        { name: 'click',  from: 'lesson_cycle', to: 'success'      }
      ]
    }

  onchangestate: ->
    console.info "Tutorial:", @current

  onwelcome: (e, f, t) =>
    Naubino.mousedown.active = false
    Naubino.mousedown.addOnce => @click()

   # give instructions
    Naubino.overlay.fade_in_message("Tutorial", null, @font_size)
    setTimeout ->
      Naubino.overlay.fade_in_message("\n\nclick to continue", null ,12)
      Naubino.mousedown.active = true
    ,1000
    setTimeout ->
      Naubino.overlay.fade_in_and_out_message(
        ["use the menu to restart this tutorial at any time",5000],
        null,
        12,
        'black',
        Naubino.Settings.canvas.width/2,
        Naubino.Settings.canvas.height-10)
    ,3000

  # fade out and then change state
  onleavewelcome: ->
    Naubino.overlay.fade_out_messages =>
      @transition()
    false

  onbeforeshown: =>
    console.warn "onbeforeshow really has been called"


  onlesson_show: =>
    strings = [
      ["Naubino is all about Naubs",100]
      ["These are Naubs",100]
      ["They always come in pairs",100]
      ["Try to move them around!",100]
    ]

    @create_naubs()
    messages = => Naubino.overlay.queue_messages(strings, (=> @shown()), @font_size)
    setTimeout messages, 2000


  onlesson_move: =>
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

    @fallback_warning_timer = setTimeout((=> Naubino.overlay.fade_in_and_out_message(["Just drag one pair across.",3000], null, @font_size)), 10000)

  # fade out and then change state
  onleavelesson_move: =>
    clearTimeout @fallback_warning_timer

    Naubino.overlay.fade_out_messages =>
      @transition()
    false


  onlesson_join: =>
    Naubino.game.joining_allowed = yes
    Naubino.naub_replaced.addOnce =>
      Naubino.overlay.fade_in_and_out_message( ["nicely done!",1000],( => Naubino.game.joining_allowed = yes), @font_size)
      Naubino.game.joining_allowed = no

    Naubino.overlay.queue_messages([
      ["very Good", 100]
      ["Every Naub has a certain color",100]
      ["You can connect pairs of Naubs...",140]
      ["...by dragging on Naub onto\nanother with the same color",300]
      ["Now try to connect two pairs of naubs!",300]
    ], null, @font_size)

  lesson_cycle: ->

  create_naubs: ->
    Naubino.game.create_matching_naubs(1)
    Naubino.game.start_timer()
    weightless = -> Naubino.game.gravity = off
    setTimeout weightless, 5500
