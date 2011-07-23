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
    canvas.onmouseup = (e) ->
      game.click e.clientX, e.clientY

    setInterval(( -> game.mainloop()), 0.1*1e3)
