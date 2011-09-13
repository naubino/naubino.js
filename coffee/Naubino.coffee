window.onload = ->
  window.foreground_canvas = document.getElementById("foreground_canvas")
  window.background_canvas = document.getElementById("background_canvas")
  window.naubino = Naubino.constructor()

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



  constructor: () ->

    @foreground = window.foreground_canvas
    @background = window.background_canvas
    @setup_keybindings()
    @setup_cursorbindings()

    @game = new @Game(@foreground, @keybindings)
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
      @game.move_pointer e.pageX - @foreground.offsetLeft, e.pageY - @foreground.offsetTop

    onmouseup = (e) =>
      #@mode.mouseup.dispatch(e)
      @game.unfocus e.pageX - @foreground.offsetLeft, e.pageY - @foreground.offsetTop

    onmousedown = (e) =>
      #@mode.mousedown.dispatch(e)
      @game.click e.pageX - @foreground.offsetLeft, e.pageY - @foreground.offsetTop

    @foreground.addEventListener("mousedown", onmousedown, false)
    @foreground.addEventListener("mouseup", onmouseup, false)
    @foreground.addEventListener("mousemove", onmousemove, false)
    @foreground.addEventListener("mouseout", onmouseup, false)

    @foreground.addEventListener("touchstart", onmousedown, false)
    @foreground.addEventListener("touchend", onmouseup, false)
    @foreground.addEventListener("touchmove", onmousemove, false)

