# @extends Game
define ["Game"], (Game) -> class StandardGame extends Game
  constructor: (canvas) ->
    super(canvas)

  ### state machine ###
  oninit: ->
    Naubino.rules_cleared = false
    @inner_clock = 0 # to avoid resetting timer after pause
    @points = 0
    basket = 150
    @basket_size = basket
    Naubino.background.basket_size = basket
    Naubino.naub_replaced.add (number)=> @graph.cycle_test(number)
    Naubino.naub_destroyed.add => @points++
    Naubino.cycle_found.add (list) => @destroy_naubs(list)

    # game parameters
    @spammer_interval = 300
    @number_of_colors = 3
    @spammers = {
      pair:   {method: @create_naub_pair,   probability: 5}
      triple: {method: @create_naub_triple, probability: 1}
    }

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



  onunset: ->
    @clear()
    @graph.clear()
    @points = 0
    Naubino.rules_cleared = true
    Naubino.add_signals()
  

  onchangestate: (e,f,t)-> #console.info "ruleset recived #{e}: #{f} -> #{t}"

  onbeforeplay: ->
    Naubino.background.animation.play()
    @animation.play()

  onplaying: -> @loop = setInterval(@event, 300 )


  onbeforepause: -> clearInterval @loop
  onbeforestop:  -> clearInterval @loop

  onpaused:      ->
    Naubino.background.animation.pause()
    @animation.pause()

  onstopped: (e,f,t) ->
    unless e is 'init'
      Naubino.background.animation.stop()
      @animation.stop()
      return true
    return true

  event: =>
    if @inner_clock == 0
      @spam()
      basket = @count_basket()
      console.log @capacity() if basket.length > 0
    @inner_clock = (@inner_clock + 1) % 10


