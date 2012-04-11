define ["Game", "Settings"], (Game, Settings) -> class StandardGame extends Game
  constructor: (canvas, graph) ->
    super(canvas, graph)

  ### state machine ###
  oninit: ->
    Naubino.rules_cleared = false
    @inner_clock = 0 # to avoid resetting timer after pause
    @points = 0
    basket = 150
    @basket_size = basket
    Naubino.background.basket_size = basket
    Naubino.naub_replaced.add (number)=> Naubino.graph.cycle_test(number)
    Naubino.naub_destroyed.add => @points++
    Naubino.cycle_found.add (list) => @destroy_naubs(list)


  onunset: ->
    @clear()
    Naubino.graph.clear()
    @points = 0
    Naubino.rules_cleared = true
  

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
      {x,y} = @random_outside()
      @create_naub_pair(x,y)
      basket = @count_basket()
      console.log basket if basket.length > 0
      console.log "new naubs! (#{@objects_count})"
    @inner_clock = (@inner_clock + 1) % 10


