class Naubino.StandartGame extends Naubino.Game
  constructor: (canvas, graph) ->
    super(canvas, graph)

  ### state machine ###
  oninit: ->
    Naubino.rules_cleared = false
    @inner_clock = 0 # to avoid resetting timer after pause
    Naubino.game.points = 0
    basket = 150
    Naubino.game.basket_size = basket
    Naubino.background.basket_size = basket
    Naubino.naub_replaced.add (number)=>
      #console.log 'naub_replaced dispatched by ',number
      Naubino.graph.cycle_test(number)

    Naubino.naub_destroyed.add =>
      Naubino.game.points++

    Naubino.cycle_found.add (list) =>
      Naubino.game.destroy_naubs(list)


  onunset: ->
    Naubino.game.clear()
    Naubino.graph.clear()
    Naubino.game.points = 0
    Naubino.rules_cleared = true
  

  onchangestate: (e,f,t)->
    console.info "ruleset recived #{e}: #{f} -> #{t}"


  onbeforepause: ->
    Naubino.game.pause()
    clearInterval(@loop)


  onbeforeplay: ->
    @loop = setInterval(@event, 300 )
    Naubino.background.play()
    Naubino.game.play()


  event: =>
    if @inner_clock == 0
      {x,y} = Naubino.game.random_outside()
      Naubino.game.create_naub_pair(x,y)
      basket = Naubino.game.count_basket()
      #console.log basket if basket.length > 0
      #console.log "new naubs!"
    @inner_clock = (@inner_clock + 1) % 10







class Naubino.TestCase extends Naubino.Game
  #  constructor: ->
  #    super()
  oninit: ->
    Naubino.Settings.show_numbers = on
    #Naubino.game.create_some_naubs 2
    Naubino.game.create_matching_naubs()
    Naubino.game.toggle_numbers()
    Naubino.game.gravity = on
    Naubino.play()
    weightless = ->
      Naubino.game.gravity = off
    setTimeout(weightless, 4000)
    basket = 150
    Naubino.game.basket_size = basket
    Naubino.background.basket_size = basket
    Naubino.background.draw()

  onunset:->
    Naubino.Settings.show_numbers = false
    Naubino.game.clear()
    Naubino.background.clear()


  event:->
    inner_basket = Naubino.game.count_basket()
    Naubino.game.destroy_naubs inner_basket

