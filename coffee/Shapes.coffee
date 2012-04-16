define -> Shapes = {
Shape: class Shape
  constructor: ->
    @style = { fill: [0,0,0,1] }

  setup: (@naub) ->
    @pos = @naub.pos
    @ctx = @naub.ctx
    @set_color_from_id @naub.color_id


  # turns the internal color init a string that applies to canvas
  color_to_rgba: (color = @style.fill, shift = 0) =>
    r = Math.round((color[0] + shift))
    g = Math.round((color[1] + shift))
    b = Math.round((color[2] + shift))
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"

  draw_shadow: (ctx) ->
    if Naubino.settings.graphics.draw_shadows
      ctx.shadowColor = "#333"
      ctx.shadowBlur = 3
      ctx.shadowOffsetX = 1
      ctx.shadowOffsetY = 1

  # sets opacity
  # @param alpha (int) value between 0 and 1
  set_opacity: (value) ->
    @style.fill[3] = value


  # change color
  set_color_from_id:(id)->
    palette = Naubino.colors
    pick = palette[id]
    @style.fill = [pick[0],pick[1],pick[2], 1]
    # TODO automatically assume 1 if alpha is unset (pick[3])
    id

  # colors the shape randomly and returns color id for comparison
  random_color: ->
    r = Math.random()
    g = Math.random()
    b = Math.random()
    @style.fill = [r,g,b,1]
    return -1

  # animates the destruction of a naub
  # @params callback [function] function that will be called after the animation has ended
  destroy_animation: (callback = null) ->
    @naub.life_rendering = on
    shrink = =>
      @naub.size *= 0.8
      @naub.join_style.width *= 0.6
      @naub.join_style.fill[3] *= 0.6
      @style.fill[3] *= 0.6
      if callback? and @naub.size <= 0.1
        clearInterval @loop
        callback.call()

    @loop = setInterval shrink, 50


Square: class Square extends Shape
  constructor: ->
    super()
    @rot = 0
  area: ->
    @width/2 * @width/2


  # actual painting routines
  render: (ctx,x,y) ->
    ctx.save()
    @width= @naub.size * 2

    @rot = @rot + 0.1
    ctx.translate( x, y)
    ctx.rotate @rot
     
    ctx.beginPath()
    ctx.rect(-@width/2,-@width/2,@width,@width)

    @draw_shadow(ctx)

    ctx.fillStyle = @color_to_rgba(@style.fill)
    ctx.fill()
    ctx.closePath()

    ctx.restore()

  isHit:(x,y) ->
    @layer.ctx.beginPath()
    @layer.ctx.rect(@pos.x-@width/2,@pos.y-@width/2,@width,@width)
    @layer.ctx.closePath()
    @layer.ctx.isPointInPath(x,y)


Ball: class Ball extends Shape
  area: ->
    # TODO consolder the margin of each naub
    Math.PI * (@naub.size/2)*(@naub.size/2)

  # actual painting routines
  # !IMPORTANT: needs to recieve ctx, x and y directly because those could also point into a buffer
  render: (ctx, x = 42, y = x) ->
    ctx.save()
    size= @naub.size

    offset = 0
    ctx.translate( x, y)
     
    ctx.beginPath()
    ctx.arc(offset, offset, size, 0, Math.PI * 2, false)
    ctx.closePath()

    ## border
    #ctx.lineWidth = 2
    #ctx.stroke()

    if @naub.focused
      # gradient
      gradient = ctx.createRadialGradient(offset, offset, size/3, offset, offset, size)
      gradient.addColorStop 0, @color_to_rgba(@style.fill, 80)
      gradient.addColorStop 1, @color_to_rgba(@style.fill, 50)
      ctx.fillStyle = gradient
    else
      ctx.fillStyle = @color_to_rgba(@style.fill)

    @draw_shadow(ctx)

    ctx.fill()
    ctx.closePath()

    ctx.restore()


Clock: class Clock extends Shape
  constructor: ->
    super()
    @start = 0
  setup: (@naub) ->
    super(@naub)
    @naub.clock_progress = 0

  # actual painting routines
  # !IMPORTANT: needs to recieve ctx, x and y directly because those could also point into a buffer
  render: (ctx, x = 42, y = x) ->
    ctx.save()
    size= @naub.size - 5

    end = @naub.clock_progress * Math.PI/100

    offset = 0
    ctx.translate( x, y)
     
    ctx.beginPath()
    ctx.arc(offset, offset, size, @start, end, false)
    #ctx.closePath()

    ctx.fillStyle = @color_to_rgba ([255,255,255,0.5])
    #ctx.fill()

    ctx.strokeStyle = ctx.fillStyle
    ctx.lineWidth = size+3
    ctx.stroke()

    ctx.closePath()

    ctx.restore()


Frame: class Frame extends Shape
  # draws a frame around the buffered image for analysis
  # @param ctx [canvas.context] context of the target layer
  constructor: (@margin = 5) ->
    super()
  setup: (@naub) ->
    super(@naub)
    @frame = @margin + @naub.size*2

  render: (ctx, x = 42, y = x) ->
    x = x-@frame/2
    y = y-@frame/2

    ctx.save()
    ctx.beginPath()
    ctx.moveTo x, y
    ctx.lineTo x, @frame+y
    ctx.lineTo @frame+x, @frame+y
    ctx.lineTo @frame+x, y
    ctx.lineTo x, y
    ctx.stroke()
    ctx.closePath()
    ctx.restore()


FrameCircle: class FrameCircle extends Frame
  render: (ctx, x = 42, y = x) ->
    ctx.save()
    ctx.beginPath()
    ctx.arc(x, y, @frame/2, 0, Math.PI * 2, false)
    ctx.closePath()
    ctx.strokeStyle = ctx.fillStyle
    ctx.stroke()
    ctx.closePath()
    ctx.restore()


PlayButton: class PlayButton extends Shape
  render: (ctx, x,y) ->
    ctx.save()
    ctx.beginPath()
    ctx.fillStyle = "#ffffff"
    ctx.moveTo(x-5,y-5)
    ctx.lineTo(x-5,y+5)
    ctx.lineTo(x+7,y+0)
    ctx.lineTo(x-5,y-5)
    ctx.closePath()
    ctx.fill()
    ctx.restore()


PauseButton: class PauseButton extends Shape
  render: (ctx, x,y) ->
    ctx.save()
    ctx.fillStyle = "#ffffff"
    ctx.beginPath()

    ctx.rect(x-5, y-6, 4, 12)
    ctx.rect(x+1, y-6, 4,12)

    ctx.closePath()
    ctx.fill()
    ctx.restore()


MainButton: class MainButton extends Square
  render: (ctx, x, y) ->
    text = Naubino.game.points ? ""
    @width = @naub.size*2.5
    ctx.save()
    ctx.translate(x,y)
    ctx.rotate(Math.PI/6)
    ctx.beginPath()
    ctx.rect(-@width/2,-@width/2,@width,@width)

    @draw_shadow(ctx)

    ctx.fillStyle = @color_to_rgba @style.fill
    ctx.fill()
    ctx.closePath()
    ctx.restore()

    ctx.save()
    ctx.translate(x,y)
    ctx.fillStyle = 'white'
    ctx.textAlign = 'center'
    ctx.font= 'bold 33px Helvetica'
    ctx.fillText(text, 0,10, @width*1.1)
    ctx.restore()


StringShape: class StringShape extends Shape
  constructor: (@string, @color = "black") ->
    super()

  setup: (@naub) ->
    super(@naub)

  render: (ctx, x,y) ->
    size = @naub.size * 1.3

    ctx.save()
    ctx.translate x,y
    ctx.fillStyle = @color
    ctx.textAlign = 'center'
    ctx.font= "#{size}px Helvetica"
    ctx.fillText(@string, 0, 6)
    ctx.restore()


NumberShape: class NumberShape extends StringShape
  constructor: ()->
    super("", "white")

  setup: (@naub)->
    super(@naub)
    @string = @naub.number

}
