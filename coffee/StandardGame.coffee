# TODO LEVEL UP
#   number of colors
#   number of naubs per spam
#   speed up
#
# @extends Game
define ["Game"], (Game) -> class StandardGame extends Game
  constructor: (canvas) ->
    super(canvas)

  ### state machine ###
  oninit: ->
    super()
    @inner_clock = 0 # to avoid resetting timer after pause
    @points = 0

    Naubino.background.basket_size = @basket_size
    @naub_replaced.add (number) => @graph.cycle_test(number)
    @naub_destroyed.add => @points++
    @cycle_found.add (list) => @destroy_naubs(list)


    @basket_size = @default_basket_size = 160
    @spammers = @default_spammers = {
      pair:
        method: => @factory.create_naub_pair(null, @max_color(), @max_color() )
        probability: 5
      mixed_pair:
        method: => @factory.create_naub_pair(null, @max_color(), @max_color(), true )
        probability: 0
      triple:
        method: => @factory.create_naub_triple(null, @max_color(), @max_color(), @max_color() )
        probability: 0
    }

    @levels = {game:this}
    StateMachine.create {
      target: @levels
      initial: 'level1'
      error:(e,f,t,a,ec,em) -> console.warn e,f,t,a,ec,em unless e is 'click'
      events: [
        { name: 'reset',  from: '*', to: 'level1'  }
        { name: 'levelUp',  from: 'level1', to: 'level2'  }
        { name: 'levelUp',  from: 'level2', to: 'level3'  }
        { name: 'levelUp',  from: 'level3', to: 'level4'  }
        { name: 'levelUp',  from: 'level4', to: 'level5'  }
        { name: 'levelUp',  from: 'level5', to: 'level6'  }
        { name: 'levelUp',  from: 'level6', to: 'level7'  }
        { name: 'levelUp',  from: 'level7', to: 'level8'  }
        { name: 'levelUp',  from: 'level8', to: 'level9'  }
      ]
      callbacks:
        onchangestate:->
          console.log @current
          unless @current == "level1"
            Naubino.overlay.animation.play()
            Naubino.overlay.fade_in_and_out_message @current,( -> Naubino.overlay.animation.stop()), 35

        onlevel1: ->
          @game.spammers = @game.default_spammers
          @game.basket_size = @game.default_basket_size

          @game.number_of_colors = 3
          @game.spammer_interval = 40 # 4 seconds
          @game.level_up_limit = 20

        onlevel2:->
          @game.number_of_colors = 4
          @game.spammer_interval = 35
          @game.level_up_limit = 45

        onlevel3:->
          @game.number_of_colors = 5
          @game.spammer_interval = 30
          @game.level_up_limit = 65

        onlevel4:->
          @game.number_of_colors = 6
          @game.spammer_interval = 25
          @game.level_up_limit = 90

        onlevel5:->
          @game.spammers.triple.probability = 1
          @game.level_up_limit = 120

        onlevel6:->
          @game.number_of_colors = Naubino.colors.length
          @game.level_up_limit = 140

        onlevel7:->
          @game.spammer_interval = 20
          @game.level_up_limit = 165

        onlevel8:->
          @game.spammers.triple.probability = 2
          @game.basket_size = 140
          @game.level_up_limit = 200

        onlevel9:->
          Naubino.overlay.animation.play()
          Naubino.overlay.fade_in_and_out_message "you got further than we implemented", Naubino.stop(yes)
          @game.level_up_limit = 250
    }


  max_color: -> Math.floor(Math.random() * (@number_of_colors))

  map_spammers: ->
    sum = 0
    for name, spammer of @spammers
      sum += spammer.probability
      {range:sum,  name, method:spammer.method}
      

  spam: ->
    probabilites = for name, spam of @spammers
      spam.probability
    max = probabilites.reduce (f,s) -> f+s
    min = 0
    dart = Math.floor(Math.random() * (max - min )) + min
    for spammer in @map_spammers()
      if dart < spammer.range
        console.log spammer.name
        spammer.method()
        return





  onchangestate: (e,f,t)-> #console.info "ruleset recived #{e}: #{f} -> #{t}"

  onbeforeplay: ->

  onplaying: ->
    super() #takes care of starting animation and physics
    Naubino.background.animation.play()
    Naubino.background.start_stepper()
    @spamming = setInterval @event, 100
    @checking = setInterval @check, 300

  onleaveplaying:->
    super() # takes care of halting physics
    clearInterval @spamming
    clearInterval @checking

  onpaused:      ->
    super() # takes care of halting animation
    Naubino.background.animation.pause()
    Naubino.background.stop_stepper()

  onbeforestop: (e,f,t) ->
    if Naubino.override
      console.log "killed"
      delete Naubino.override
      return true
    else
      confirm "do you realy want to stop the game?"

  onstopped: (e,f,t) ->
    unless e is 'init'
      Naubino.background.animation.stop()
      Naubino.background.stop_stepper()
      @animation.stop()
      @levels.reset()
      @stop_stepper()
      @clear()
      @clear_objects()
      @points = 0
    else
      console.info "game initialized"
    return true

  check: =>
    capacity = @capacity()
    critical_capacity = 35

    # start warning 
    if @capacity() < critical_capacity
      if Naubino.background.pulsating == off
        Naubino.background.start_pulse()
      Naubino.background.ttl = Math.floor capacity/2
    else if Naubino.background.pulsating == on
      Naubino.background.stop_pulse()
      Naubino.background.ttl = critical_capacity

    @lost() if @capacity() < 10
    @levels.levelUp() if @points > @level_up_limit

  lost: ->
    Naubino.pause()
    Naubino.overlay.animation.play()
    Naubino.overlay.warning "Naub Overflow", @basket_size/4
    console.error "you lost", @levels.current


  event: =>
    @spam() if @inner_clock == 0
    @inner_clock = (@inner_clock + 1) % @spammer_interval


