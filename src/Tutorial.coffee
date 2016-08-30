define ["Game"], (Game) ->\

class Tutorial extends Game
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
  #   Naubs keep being generated
  #   Too many Naubs can kill you
  ###

  constructor: (canvas, graph) ->
    super(canvas, graph)
    @multiplicator = 10 # 100

  configure: ->
    Naubino.overlay.animation.play()
    Naubino.background.animation.stop() unless Naubino.background.animation.current == "stopped"
    @font_size = 24
    @joining_allowed = no

    @lessons = StateMachine.create @lesson_steps = {
      initial: 'welcome'
      error:(e,f,t,a,ec,em) -> console.warn e,f,t,a,ec,em unless e is 'click'

      events: [
        { name: 'click',  from: 'welcome',      to: 'lesson_show'  }
        { name: 'shown',  from: 'lesson_show',  to: 'lesson_move'  }
        { name: 'moved',  from: 'lesson_move',  to: 'lesson_join'  }
        { name: 'joined', from: 'lesson_join',  to: 'lesson_cycle' }
        { name: 'click',  from: 'lesson_cycle', to: 'success'      }
      ]
      callbacks:{
        onchangestate:(e,f,t) ->
          console.info "Tutorial:", @current
          console.info "#{f} --(#{e})--> #{t}"

        onwelcome: (e, f, t) =>
          Naubino.mousedown.active = false
          Naubino.mousedown.add => @lessons.click()

         # give instructions
          Naubino.overlay.fade_in_message({text:"Tutorial", fontsize:24})
          setTimeout ->
            Naubino.overlay.fade_in_message({text:"\n\nclick to continue", fontsize:12})
            Naubino.mousedown.active = true
          ,10*@multiplicator
          setTimeout =>
            pos = @center.Copy()
            pos.add cp.v(0, @height/2-10)
            Naubino.overlay.fade_in_and_out_message(
              {text:"use the menu to restart this tutorial at any time",duration:5, fontsize:12, pos:pos}
            )
          ,30*@multiplicator

        # fade out and then change state
        onleavewelcome: =>
          Naubino.overlay.fade_out_messages => @lessons.transition()
          false

        onclick: =>

        onlesson_show: =>
          setTimeout =>
            @create_naubs()
            @for_each (naub) -> naub.disable()
            console.warn "naubs inserted"
          , 43*@multiplicator

          strings = [
            {text:"Lesson 1"                   , duration:1.3, fontsize: @font_size*2}
            {text:"Naubino is all about Naubs" , duration:1.0}
            {text:"These are Naubs"            , duration:1.0}
            {text:"They always come in pairs"  , duration:1.0}
            {text:"Try to move them around!"   , duration:1.0}
          ]

          messages = => Naubino.overlay.queue_messages(strings, (=> @lessons.shown()))
          messages()
          #setTimeout messages, 20*@multiplicator


        onlesson_move: =>
          @for_each (naub) -> naub.enable()
          # remember a naubs original position
          binding1 = @naub_focused.add (naub) =>
            naub.old_pos = naub.physics.pos.Copy()

          # compare it with the new position
          binding2 = @naub_unfocused.add (naub) =>
            new_pos = naub.physics.pos.Copy()
            new_pos.Subtract naub.old_pos
            dragged_distance = new_pos.Length()
            if dragged_distance > 180
              # removing listeners
              binding1.detach()
              binding2.detach()
              @lessons.moved()

          @fallback_warning_timer = setTimeout((=> Naubino.overlay.fade_in_and_out_message(["Just drag one pair across.",30*@multiplicator], null, @font_size)), 100*@multiplicator)

        # fade out and then change state
        onleavelesson_move: =>
          clearTimeout @fallback_warning_timer
          Naubino.overlay.fade_out_messages => @transition()
          false


        onlesson_join: =>
          @joining_allowed = no
          @naub_replaced.addOnce =>
            Naubino.overlay.queue_messages([["nicely done!",20*@multiplicator]], =>
              @lessons.joined()
            , @font_size)
            @toggle_joining()

          Naubino.overlay.queue_messages([
            ["very Good", 10*@multiplicator]
            ["Every Naub has a certain color",10*@multiplicator]
            ["You can connect pairs of Naubs...",14*@multiplicator]
            ["...by dragging on Naub onto\nanother with the same color",30*@multiplicator]
            ["Now try to connect two pairs of naubs!",30*@multiplicator]
          ], @toggle_joining, @font_size)


        onlesson_cycle: (e,f,t) =>
          @cycle_found.add =>
            Naubino.overlay.queue_messages([
              ["Great",40*@multiplicator]
            ], null, @font_size)

          Naubino.overlay.queue_messages([
            ["now connect the remaining naubs",25*@multiplicator]
            ["and see what happens...", 20*@multiplicator]
          ], @toggle_joining, @font_size)

        onsuccess: =>
          console.info

            
      }
    }

  onbeforestop: (e,f,t) ->
    Naubino.leave_tutorial()

  onstopped: (e,f,t) ->
    unless e is 'init'
      Naubino.overlay.animation.stop()
      @animation.stop()
      @levels.reset()
      @stop_stepper()
      @clear()
      @clear_objects()
      @points = 0
      console.info "Tutorial stopped"
    else
      console.info "Tutorial initialized"
      @configure()
    return true



  ### utility ###

  toggle_joining: =>
    @joining_allowed = !@joining_allowed
    console.log "joining_allowed", @joining_allowed

  create_naubs: ->
    @gravity = on
    @factory.create_matching_naubs(1,1)
    @start_stepper()
    weightless = -> @gravity = off
    setTimeout weightless, 55*@multiplicator
