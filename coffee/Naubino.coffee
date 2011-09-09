game =          require 'javascripts/Game.js'
keybindings =   require 'javascripts/Keybindings.js'
naub =          require 'javascripts/Naub.js'
naubshape =     require 'javascripts/NaubShape.js'
naubball =      require 'javascripts/NaubBall.js'
physicsmodel =  require 'javascripts/PhysicsModel.js'
world =         require 'javascripts/World.js'
graph =         require 'javascripts/Graph.js'
settings =      require 'javascripts/Settings.js'
b2vec2 =        require 'lib/b2Vec2.js'
underscore =    require 'lib/underscore/underscore.js'


window.onload = ->
  canvas = document.getElementById("canvas")
  window.naubino = new Naubino(canvas)

class Naubino

  constructor: (@canvas) ->
    #context = @canvas.getContext("2d")
    @setup_keybindings()
    @setup_cursorbindings()

    @game = new Game(@canvas, @keybindings)

    @game.create_some_naubs(12)
    @game.start_timer()

    @keybindings.enable 32, => @game.pause()






  setup_keybindings: () ->
    @keybindings = new window.KeyBindings()
    window.onkeydown = (key) => @keybindings.keydown(key)
    window.onkeyup = (key) => @keybindings.keyup(key)


  setup_cursorbindings: () ->
    onmousemove = (e) =>
      @game.move_pointer e.pageX - @canvas.offsetLeft, e.pageY - @canvas.offsetTop

    onmouseup = (e) =>
      @game.unfocus e.pageX - @canvas.offsetLeft, e.pageY - @canvas.offsetTop

    onmousedown = (e) =>
      @game.click e.pageX - @canvas.offsetLeft, e.pageY - @canvas.offsetTop

    @canvas.addEventListener("mousedown", onmousedown, false)
    @canvas.addEventListener("mouseup", onmouseup, false)
    @canvas.addEventListener("mousemove", onmousemove, false)

    #canvas.addEventListener("touchstart", touchDown, false)
    #canvas.addEventListener("touchend", touchUp, false)
    #canvas.addEventListener("touchmove", touchXY, false)

