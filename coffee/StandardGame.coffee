# TODO LEVEL UP
#   number of colors
#   number of naubs per spam
#   speed up
#
# @extends Game
define ["Game"], (Game) -> class StandardGame extends Game
  constructor: (canvas) ->
    super(canvas)

  calculate_points: (list) ->
    @ex_naubs += list.length
    max_grow = 3 # may be moved to settings some day
    factor = (max_grow-1) / @max_naubs
    p = Math.floor(factor * list.length * list.length)
    @points += p
    if p > 0
      Naubino.overlay.fade_in_and_out_message ("\n\nChain Bonus "+p)

  ### state machine ###
  oninit: ->
    super()

    Naubino.background.basket_size = @basket_size
    @naub_replaced.add (number)    => @graph.cycle_test(number)
    @naub_destroyed.add (id)       => @points += @get_object(id).points_on_destroy()
    @cycle_found.add (list)        => @destroy_naubs(list)
    @cycle_found.add (list)        => @calculate_points(list)
    
    #Naubino.audio.connect_to_game this
    @number_of_colors = @default_number_of_colors = 3
    #@basket_size      = @default_basket_size      = 160

    @spammers = {
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

    @inner_clock = 0 # to avoid resetting timer after pause
    @points = 0
    @ex_naubs = 0
    @naubs_count = 0
    @load_level 0

  level_details: [
    { limit:-1,  number_of_colors: 3, interval: 40, max_naubs: 20, probabilities:{ pair:1, mixed_pair:0, triple: 0 } }
    { limit:30,  number_of_colors: 3, interval: 40, max_naubs: 20 } #1
    { limit:60,  number_of_colors: 3, interval: 37, max_naubs: 25, probabilities:{ pair:.9, mixed_pair: 0, triple: .1 } } #2
    { limit:90,  number_of_colors: 4, interval: 33, max_naubs: 30 } #3
    { limit:120, number_of_colors: 4, interval: 30, max_naubs: 35, probabilities:{ pair:.8, mixed_pair: 0, triple: .2 } } #4
    { limit:150, number_of_colors: 5, interval: 27, max_naubs: 40 } #5
    { limit:180, number_of_colors: 5, interval: 23, max_naubs: 43, probabilities:{ pair:.6, mixed_pair: 0, triple: .4 } } #6
    { limit:210, number_of_colors: 5, interval: 20, max_naubs: 45 } #7
    { limit:240, number_of_colors: 5, interval: 18, max_naubs: 47, probabilities:{ pair:.4, mixed_pair: 0, triple: .6 } } #8
    { limit:270, number_of_colors: 5, interval: 16, max_naubs: 49 } #9
    { limit:30000, number_of_colors: 5, interval: 15, max_naubs: 50, probabilities:{ pair:.2, mixed_pair: 0, triple: .8 } } #10
  ]

  load_level: (level) ->
    if @level_details.length >= level
      @load_level 0 if 0 < level < @level

      @level = level
      name = "Level #{@level}"
      Naubino.overlay.fade_in_and_out_message name unless level == 0
      set = @level_details[@level]

      #@basket_size      = set['basket_size']      ? @basket_size
      @max_naubs      = set['max_naubs']      ? @max_naubs
      @number_of_colors = set['number_of_colors'] ? @number_of_colors
      @spammer_interval = set['interval']         ? @spammer_interval

      console.log "limit"            , set['limit']
      #console.log "basket size"      , @basket_size
      console.log "number of colors" , @number_of_colors
      console.log "spammerinterval"  , @spammer_interval

      for name, probability of set['probabilities']
        console.log name
        @spammers[name].probability = probability

  max_color: -> Math.floor(Math.random() * (@number_of_colors))

  map_spammers: ->
    sum = 0
    for name, spammer of @spammers
      sum += spammer.probability
      {range:sum,  name, method:spammer.method}
      

  spam: ->
    probabilities = for name, spam of @spammers
      spam.probability
    max = probabilities.reduce (f,s) -> f+s
    min = 0
    dart = Math.floor(Math.random() * (max - min )) + min
    for spammer in @map_spammers()
      if dart < spammer.range
        console.log spammer.name
        spammer.method()
        return


  onchangestate: (e,f,t)-> #console.info "ruleset recived #{e}: #{f} -> #{t}"

  onbeforeplay: (e,f,t) ->
    console.time('st-game')


  onplaying: ->
    console.timeEnd('st-game')
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
      @level  = 0
      @stop_stepper()
      @clear()
      @clear_objects()
      @points = 0
      @ex_naubs = 0
    else
      console.info "game initialized"
    return true

  check: =>
    console
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

    @load_level(@level+1) if @level_details[@level].limit < @ex_naubs

  lost: ->
    Naubino.pause()
    #Naubino.overlay.warning "Naub Overflow", @basket_size/4
    console.error "you lost", @level_details.current


  event: =>
    @spam() if @inner_clock == 0
    @inner_clock = (@inner_clock + 1) % @spammer_interval
    @spammer_interval



