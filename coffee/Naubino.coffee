require 'javascripts/Game.js'
require 'javascripts/Keybindings.js'
require 'javascripts/Naub.js'
require 'javascripts/NaubShape.js'
require 'javascripts/PhysicsModel.js'
require 'javascripts/World.js'
require 'javascripts/Graph.js'
require 'lib/b2Vec2.js'

window.onload = ->
  canvas = document.getElementById("canvas")
  window.naubino = new Naubino(canvas)

class Naubino
  constructor: (@canvas) ->
    #context = @canvas.getContext("2d")
    @setup_keybindings()
    @setup_cursorbindings()
    @game = new Game(@canvas, @keybindings)
    @game.create_some_naubs()
    @game.start_timer()


  setup_keybindings: () ->
    @keybindings = new window.KeyBindings()
    window.onkeydown = (key) => @keybindings.keydown(key)
    window.onkeyup = (key) => @keybindings.keyup(key)

  setup_cursorbindings: () ->
    @canvas.onmousemove = (e) ->
    @canvas.onmousedown = (e)->
    onmouseup = (e) =>
      @game.click e.pageX - @canvas.offsetLeft, e.pageY - @canvas.offsetTop

    @canvas.addEventListener("mousedown", onmouseup, false)
    #canvas.addEventListener("mousemove", mouseXY, false)
    #canvas.addEventListener("touchstart", touchDown, false)
    #canvas.addEventListener("touchend", touchUp, false)
    #canvas.addEventListener("touchmove", touchXY, false)

