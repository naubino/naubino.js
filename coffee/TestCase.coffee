define ["Game"], (Game) -> class TestCase extends Game
  #  constructor: ->
  #    super()
  oninit: ->
    #@create_some_naubs 2
    @create_matching_naubs()
    @gravity = on
    Naubino.naub_replaced.add (number)=> Naubino.graph.cycle_test(number)
    Naubino.cycle_found.add (list) => @destroy_naubs(list)
    Naubino.play()

  onplaying: ->
    weightless = => @gravity = off
    #setTimeout(weightless, 4000)
    Naubino.settings.updating = off

    basket = 150
    @animation.play()
    @basket_size = basket
    Naubino.background.basket_size = basket
    Naubino.background.draw()

  onpaused: ->
    @animation.pause()

  onunset:->
    Naubino.add_signals()
    console.log("standart_game clear")
    Naubino.settings.show_numbers = false
    @clear()
    Naubino.background.clear()


  event:->
    inner_basket = @count_basket()
    @destroy_naubs inner_basket

  filling_level: ->
    bs = @basket_size/2
    console.info Math.ceil bs * bs * Math.PI
    @filling =0
    for naub in @count_basket()
      @filling += naub.area()
    console.warn @filling
