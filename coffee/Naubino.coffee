window.onload = ->
  canvas = document.getElementById("canvas")
  window.naubino = Naubino.constructor(canvas)

@Naubino = new ->
  require 'lib/jquery-1.6.3.min.js'
  require 'lib/underscore/underscore.js'
  require 'lib/signals/signals.min.js'
  require 'lib/b2Vec2.js'
  require 'js/Game.js'
  require 'js/GameModes.js'
  require 'js/Keybindings.js'
  require 'js/Naub.js'
  require 'js/NaubShape.js'
  require 'js/NaubBall.js'
  require 'js/PhysicsModel.js'
  require 'js/World.js'
  require 'js/Graph.js'
  require 'js/Settings.js'



  constructor: (@canvas) ->

    @setup_keybindings()
    @setup_cursorbindings()

    @game = new @Game(@canvas, @keybindings)
    @game.create_some_naubs(12)
    @game.start_timer()

    @keybindings.enable 32, => @game.pause()

    @mode = new @GameMode(@game)

  setup_keybindings: () ->
    @keybindings = new @KeyBindings()
    window.onkeydown = (key) => @keybindings.keydown(key)
    window.onkeyup = (key) => @keybindings.keyup(key)


  setup_cursorbindings: () ->
    onmousemove = (e) =>
      #@mode.mousemove.dispatch(e)
      @game.move_pointer e.pageX - @canvas.offsetLeft, e.pageY - @canvas.offsetTop

    onmouseup = (e) =>
      #@mode.mouseup.dispatch(e)
      @game.unfocus e.pageX - @canvas.offsetLeft, e.pageY - @canvas.offsetTop

    onmousedown = (e) =>
      #@mode.mousedown.dispatch(e)
      @game.click e.pageX - @canvas.offsetLeft, e.pageY - @canvas.offsetTop

    @canvas.addEventListener("mousedown", onmousedown, false)
    @canvas.addEventListener("mouseup", onmouseup, false)
    @canvas.addEventListener("mousemove", onmousemove, false)

    @canvas.addEventListener("touchstart", onmousedown, false)
    @canvas.addEventListener("touchend", onmouseup, false)
    @canvas.addEventListener("touchmove", onmousemove, false)

