Naubino.Layer = class Layer

  constructor: (@canvas) ->
    @width = @canvas.width
    @height = @canvas.height
    @center = new b2Vec2 @width/2, @height/2
    @ctx = @canvas.getContext('2d')


  draw: ->
  step: (dt) ->

Naubino.Background = class Background extends Naubino.Layer

  draw: (context) ->
    width = Naubino.background_canvas.width
    height = Naubino.background_canvas.foreground.height
    centerX = width/2
    centerY = height/2

    context.clearRect(0, 0, Naubino.background_canvas.width, Naubino.background_canvas.height)

    context.save()
    context.beginPath()
    context.arc centerX, centerY, 160, 0, Math.PI*2, false

    context.lineWidth = 5
    context.strokeStyle = "black"
    context.stroke()
    context.closePath()
    context.restore()
    
