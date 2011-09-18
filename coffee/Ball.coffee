Naubino.Ball = class Ball extends Naubino.Shape
  constructor: (@naub) ->
    super(@naub)

  # inherits : 
  #
  #   draw()
  #   pre_render()
  #   render()
  #   color_to_rgba()
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
      gradient = ctx.createRadialGradient(offset, offset, size/2, offset, offset, size)
      gradient.addColorStop 0, @color_to_rgba(@style.fill, 3)
      gradient.addColorStop 1, @color_to_rgba @style.fill
      ctx.fillStyle = gradient
    else
      ctx.fillStyle = @color_to_rgba(@style.fill)

    # shadow
    #ctx.shadowColor = "#333"
    #ctx.shadowBlur = 3
    #ctx.shadowOffsetX = 1
    #ctx.shadowOffsetY = 1

    ctx.fill()

    if Naubino.Settings.show_numbers
      ctx.fillStyle = 'white'
      ctx.textAlign = 'center'
      ctx.font= '10pt Helvetica'
      ctx.fillText(@naub.number, offset, offset+5)

    ctx.closePath()
    ctx.restore()

  draw_join: (ctx, partner) ->
    super(ctx, partner)
    
