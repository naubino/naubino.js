define ["Game", "Settings"], (Game, Settings) -> class TestCase extends Game
  #  constructor: ->
  #    super()
  oninit: ->
    Settings.show_numbers = on
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
    console.log("standart_game clear")
    Settings.show_numbers = false
    @clear()
    Naubino.background.clear()


  event:->
    inner_basket = @count_basket()
    @destroy_naubs inner_basket

