define ["Game", "Settings"], (Game, Settings) -> class TestCase extends Game
  #  constructor: ->
  #    super()
  oninit: ->
    Settings.show_numbers = on
    #@create_some_naubs 2
    @create_matching_naubs()
    @gravity = on

  onplaying: ->
    weightless = => @gravity = off
    #setTimeout(weightless, 4000)
    Naubino.Settings.updating = off

    basket = 150
    @animation.play()
    @basket_size = basket
    Naubino.background.basket_size = basket
    Naubino.background.draw()

  onpaused: ->
    @animation.pause()

  onunset:->
    console.log("standart_game clear")
    Naubino.Settings.show_numbers = false
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
