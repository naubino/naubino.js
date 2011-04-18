class Game
    constructor: (@canvas, @bindings) ->
        @width = @canvas.width
        @height = @canvas.height
        field = [0, 0, @width, @height]
        @world = new World field


    step: (dt) ->
    
    draw: (ctx) ->
        ctx.save()
        naubi = new Naub
        naubi.draw(ctx)
        ctx.restore()

