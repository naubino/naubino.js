define -> Shapes = {
Shape: class Shape
  constructor: ->

  setup: (@naub) ->
    @pos      = @naub.pos
    @ctx      = @naub.ctx
    @radius   = @naub.radius - Naubino.settings.naub.margin/2
    @width    = @naub.width - Naubino.settings.naub.margin
    @height   = @naub.height - Naubino.settings.naub.margin

  apply_filters: (filters, ctx )->
    for filter in filters
      @apply_filter(filter, ctx)

  apply_filter: (filter, ctx )->
    @[filter](ctx) if filter in [ "alpha", "draw_glow", "draw_border", "draw_shadow", "draw_gradient" ]
  
  alpha: (ctx) ->
    ctx.globalAlpha = 0.4

  # !IMPORTANT: needs to recieve ctx, x and y directly because those could also point into a buffer
  draw: (ctx, x = 42, y = x) ->
    ctx.save()
    ctx.translate x, y
    ctx.scale @naub.style.scale, @naub.style.scale if @naub.style.scale?

    @render ctx, x, y

    @apply_filters @naub.style.filters, ctx if @naub.style.filters?
    @apply_filter "draw_border", ctx if Naubino.settings.graphics.draw_borders
    #@apply_filter "draw_gradient", ctx if @naub.is_active()
    if @naub.is_active() && Object.keys(@naub.joins).length == 1
      @apply_filter "draw_glow", ctx
      @apply_filter "draw_gradient", ctx

    ctx.restore()
     
  draw_border: (ctx) ->
    ctx.lineWidth = 2
    ctx.strokeStyle = Util.color_to_rgba @naub.join_style.fill
    ctx.stroke()

  draw_gradient: (ctx) ->
    gradient = ctx.createRadialGradient(0, 0, @radius/3, 0, 0, @radius)
    gradient.addColorStop 0, Util.color_to_rgba(@naub.style.fill, 60)
    gradient.addColorStop 1, Util.color_to_rgba(@naub.style.fill, 30)
    ctx.fillStyle = gradient
    ctx.fill()

  draw_glow: (ctx) ->
    ctx.shadowColor = Util.color_to_rgba(@naub.style.fill)
    ctx.shadowBlur = 10
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 0
    ctx.fill()

  draw_shadow: (ctx) ->
    ctx.shadowColor = "#333"
    ctx.shadowBlur = 3
    ctx.shadowOffsetX = 1
    ctx.shadowOffsetY = 1
    ctx.fill()

  # animates the destruction of a naub
  # @params callback [function] function that will be called after the animation has ended
  destroy_animation: (duration) -> @naub.life_rendering = on


Ball: class Ball extends Shape

  # actual painting routines
  render: (ctx, x = 42, y = x) ->
    ctx.beginPath()
    ctx.arc(0, 0, @radius, 0, Math.PI * 2, false)
    ctx.fillStyle = Util.color_to_rgba(@naub.style.fill)
    ctx.fill()

    ctx.closePath()

  isHit: (ctx, pos) ->
    d = @naub.pos.Copy()
    d.sub pos
    d.Length() <= @naub.size

  setup: (naub) ->
    super(naub)

Box: class Box extends Shape
  constructor: ->
    super()
    @rot = Math.random() * Math.PI

  area: -> @width/2 * @width/2

  setup: (naub) ->
    naub.width  = naub.size * 0.7
    naub.height = naub.size * 0.7
    super(naub)


  # actual painting routines
  render: (ctx,x,y) ->
    ctx.rotate @naub.physical_body.a if @naub.physical_body?
     
    ctx.beginPath()
    ctx.rect(-@naub.width/2,-@naub.height/2,@naub.width,@naub.height)
    ctx.fillStyle = Util.color_to_rgba(@naub.style.fill)
    ctx.fill()
    ctx.closePath()

  adjust_physics: ->
    @naub.momentum = cp.momentForBox( Naubino.settings.naub.mass, @naub.width, @naub.height )
    @naub.physical_body = new cp.Body( Naubino.settings.naub.mass, @naub.momentum )
    @naub.physical_body.setAngle( 0 ) # remember to set position
    @naub.physical_shape = new cp.BoxShape( @naub.physical_body, @naub.width, @naub.height )
    @naub.physical_shape.setElasticity @naub.elasticity
    @naub.physical_shape.setFriction @naub.friction
  isHit: (ctx, pos) ->
    ctx.beginPath()
    ctx.rect(-@naub.width/2,-@naub.height/2,@naub.width,@naub.height)
    ctx.closePath()
    ctx.isPointInPath(pos.x,pos.y)


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
    size= @naub.size - 5

    end = @naub.clock_progress * Math.PI/100

    ctx.translate( x, y)
     
    ctx.beginPath()
    ctx.arc(0, 0, size, @start, end, false)
    #ctx.closePath()

    ctx.fillStyle = Util.color_to_rgba ([255,255,255,0.5])
    #ctx.fill()

    ctx.strokeStyle = ctx.fillStyle
    ctx.lineWidth = size+3
    ctx.stroke()

    ctx.closePath()



Frame: class Frame extends Shape
  # draws a frame around the buffered image for analysis
  # @param ctx [canvas.context] context of the target layer
  constructor: (@margin = null) ->
    super()
  setup: (@naub) ->
    super(@naub)
    if @margin?
      @frame = @margin + @naub.size
    else
      @frame = @naub.frame+ @naub.size*2


  render: (ctx, x = 42, y = x) ->
    x = x-@frame/2
    y = y-@frame/2

    ctx.beginPath()
    ctx.moveTo x, y
    ctx.lineTo x, @frame+y
    ctx.lineTo @frame+x, @frame+y
    ctx.lineTo @frame+x, y
    ctx.lineTo x, y
    ctx.stroke()
    ctx.closePath()


FrameCircle: class FrameCircle extends Frame
  render: (ctx, x = 42, y = x) ->
    ctx.beginPath()
    r = @naub.physics.margin * @naub.size
    ctx.arc(x, y, r, 0, Math.PI * 2, false)
    ctx.closePath()
    ctx.strokeStyle  = "black"
    fill = @naub.style.fill
    fill[3] = 0.3
    ctx.fillStyle  = Util.color_to_rgba(fill)
    ctx.stroke()
    ctx.fill()
    ctx.closePath()


PlayButton: class PlayButton extends Shape
  draw: (ctx, x,y) ->
    ctx.save()
    ctx.beginPath()
    ctx.fillStyle = "#ffffff"
    ctx.moveTo(x-7,y-7)
    ctx.lineTo(x-7,y+7)
    ctx.lineTo(x+9,y+0)
    ctx.lineTo(x-7,y-7)
    ctx.closePath()
    ctx.fill()
    ctx.restore()


PauseButton: class PauseButton extends Shape
  draw: (ctx, x,y) ->
    ctx.save()
    ctx.fillStyle = "#ffffff"
    ctx.beginPath()

    ctx.rect(x-7, y-7, 5,13)
    ctx.rect(x+1, y-7, 5,13)

    ctx.closePath()
    ctx.fill()
    ctx.restore()


MainButton: class MainButton extends Box
  draw: (ctx, x, y) ->
    text = Naubino.game.points ? ""
    size=38
    @width = @naub.size*1.2
    ctx.save()
    ctx.translate(x,y)
    ctx.rotate(Math.PI/6)
    ctx.beginPath()
    ctx.rect(-@width/2,-@width/2,@width,@width)

    @apply_filters @naub.filters, ctx if @naub.filters?
    @apply_filter "draw_border", ctx if Naubino.settings.graphics.draw_borders

    ctx.fillStyle = Util.color_to_rgba @naub.style.fill
    ctx.fill()
    ctx.closePath()
    ctx.restore()

    l = text.toString().length
    switch l
      when 1,2 then ratio = 1
      when 3 then ratio = 0.7
      when 4 then ratio = 0.5
      else ratio = 0.4

    ctx.save()
    ctx.translate(x,y)
    ctx.scale ratio, ratio
    
    ctx.font= "bold #{size}px #{Naubino.settings.menu.font}"
    ctx.textAlign = 'center'
    if Naubino.settings.graphics.draw_borders
      ctx.fillStyle = 'black'
      ctx.fillText(text, 2,11)
      ctx.fillText(text, 2,13)
      ctx.fillText(text, 1,12)
      ctx.fillText(text, 3,12)
      ctx.fillText(text, 4,14)
    ctx.fillStyle = 'white'
    ctx.fillText(text, 2,12)

    ctx.restore()


StringShape: class StringShape extends Shape
  constructor: (@string, @color = "black") ->
    super()

  setup: (@naub) ->
    super(@naub)

  draw: (ctx, x,y) ->
    size = @naub.size * .5
    if typeof @string == "function"
      string = @string()
    else
      string = @string

    ctx.save()
    ctx.translate x,y
    ctx.scale @naub.style.scale, @naub.style.scale if @naub.style.scale?
    ctx.rotate @naub.physical_body.a if @naub.physical_body?
    ctx.fillStyle = @color
    ctx.textAlign = 'center'
    ctx.font= "#{size}px #{Naubino.settings.game.font}"
    ctx.fillText(string, 0, 7)
    ctx.restore()

}
