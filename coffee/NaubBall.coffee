Naubino.NaubBall = class NaubBall extends Naubino.NaubShape
  constructor: (naub) ->
    super(naub)

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

    if @naub.focused
      # gradient
      gradient = ctx.createRadialGradient(offset,offset, size,0, size, size)
      gradient.addColorStop 0, @color_to_css @style.fill
      gradient.addColorStop 1, @color_to_css(@style.fill, 1.7)
      ctx.fillStyle = gradient
    else
      ctx.fillStyle = @color_to_css(@style.fill)

    # shadow
    ctx.shadowColor = "#333"
    ctx.shadowBlur = 3
    ctx.shadowOffsetX = 2
    ctx.shadowOffsetY = 2

    ctx.fill()

    #ctx.fillStyle = 'white'
    #ctx.textAlign = 'center'
    #ctx.font= '10pt Helvetica'
    #ctx.fillText(@naub.number, offset, offset+5)

    ctx.closePath()
    ctx.restore()

  draw_join: (ctx, partner) ->
    super(ctx, partner)
    
