class Naubino.StandartGame extends Naubino.Game
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
  

  onchangestate: (e,f,t)->
    #console.info "ruleset recived #{e}: #{f} -> #{t}"


  onbeforepause: =>
    clearInterval @loop

  onbeforeplay: ->
    Naubino.background.animation.play()

  onplaying: =>
    @loop = setInterval(@event, 300 )
    @animation.play()

  onpaused: =>
    @animation.pause()

  event: =>
    if @inner_clock == 0
      {x,y} = @random_outside()
      @create_naub_pair(x,y)
      basket = @count_basket()
      #console.log basket if basket.length > 0
      console.log "new naubs! (#{@objects_count})"
    @inner_clock = (@inner_clock + 1) % 10







class Naubino.TestCase extends Naubino.Game
  #  constructor: ->
  #    super()
  oninit: ->
    Naubino.Settings.show_numbers = on
    #@create_some_naubs 2
    @create_matching_naubs()
    @toggle_numbers()
    @gravity = on

  onplaying: ->
    weightless = => @gravity = off
    setTimeout(weightless, 4000)

    basket = 150
    @animation.play()
    @basket_size = basket
    Naubino.background.basket_size = basket
    Naubino.background.draw()

  onpaused: ->
    @animation.pause()

  onunset:->
    Naubino.Settings.show_numbers = false
    @clear()
    Naubino.background.clear()


  event:->
    inner_basket = @count_basket()
    @destroy_naubs inner_basket

