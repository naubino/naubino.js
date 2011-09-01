require 'javascripts/Game.js'
require 'javascripts/Keybindings.js'
require 'javascripts/Naub.js'
require 'javascripts/NaubShape.js'
require 'javascripts/PhysicsModel.js'
require 'javascripts/World.js'
require 'lib/b2Vec2.js'

window.onload = ->
    canvas = document.getElementById("canvas")
    ctx = canvas.getContext("2d")

    keybindings = new window.KeyBindings()
    window.onkeydown = (key) -> keybindings.keydown(key)
    window.onkeyup = (key) -> keybindings.keyup(key)

    game = new Game(canvas, keybindings)
    game.create_some_naubs 6

    canvas.onmousemove = (e) ->
    canvas.onmousedown = (e)->
    onmouseup = (e) ->
      game.click e.pageX - canvas.offsetLeft, e.pageY - canvas.offsetTop

    canvas.addEventListener("mousedown", onmouseup, false)
    #canvas.addEventListener("mousemove", mouseXY, false)
    #canvas.addEventListener("touchstart", touchDown, false)
    #canvas.addEventListener("touchend", touchUp, false)
    #canvas.addEventListener("touchmove", touchXY, false)

    setInterval(( -> game.mainloop()), 0.1*1e3)
