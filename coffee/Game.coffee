window.Game = class Game
    constructor: (@canvas, @bindings) ->
        @width = @canvas.width
        @height = @canvas.height

    step: (dt) ->
    
    draw: (ctx) ->
        ctx.save()
        naubi = new Naub
        naubi.draw(ctx)
        ctx.restore()

