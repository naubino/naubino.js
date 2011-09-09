Naubino.NaubBall = class NaubBall extends Naubino.NaubShape
  constructor: (naub) ->
    @naub = naub
    @pos = naub.physics.pos
    @size = 14
    @frame = @size+5
    @style = { fill: [0,0,0,1] }

  # inherits : 
  #
  #   draw()
  #   pre_render()
  #   render()
  #   color_to_css()
  #   random_palette_color()
  #   random_color()


  ### actual painting routines ###
  render: (ctx, offset = @frame) ->
    ctx.save()
    pos = @pos
    size= @size

    if offset == 0
      ctx.translate(pos.x, pos.y)
      
    ctx.beginPath()
    ctx.arc(offset, offset, size, 0, Math.PI * 2, false)
    ctx.closePath()
    ctx.fillStyle = @color_to_css(@style.fill)

    if @naub.focused
      # gradient
      gradient = ctx.createRadialGradient(offset,offset, size,0, size, size)
      gradient.addColorStop 0, @color_to_css @style.fill
      gradient.addColorStop 1, @color_to_css @style.fill, 1.7
      ctx.fillStyle = gradient

    # shadow
    ctx.shadowColor = "#333"
    ctx.shadowBlur = 3
    ctx.shadowOffsetX = 2
    ctx.shadowOffsetY = 2

    ctx.fill()

    if @naub.focused
      ctx.fillStyle = 'white'
      content.textAlign = 'center'
      ctx.font= '10pt Helvetica'
      ctx.fillText(@naub.number, offset-7, offset+5)

    ctx.closePath()
    ctx.restore()

  draw_join: (ctx, partner) ->
    super(ctx, partner)
    
