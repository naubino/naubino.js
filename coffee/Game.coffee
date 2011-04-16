window.Game = class Game
    constructor: (@canvas, @bindings) ->
        @width = @canvas.width
        @height = @canvas.height

    step: (dt) ->
    
    draw: (ctx) ->
        ctx.save()
        ctx.restore()

