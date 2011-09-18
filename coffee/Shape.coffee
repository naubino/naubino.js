Naubino.Shape = class Shape

  constructor: (naub) ->
    @naub = naub
    @pos = naub.physics.pos
    @size = @naub.size
    @frame = @size+5
    @style = { fill: [0,0,0,1] }
    @join_style = { fill: [0,0,0,1], width: 6 }
    @life_rendering = false # if true redraw on each frame

  draw: (ctx) ->
    if Naubino.Settings.pre_rendering and not @life_rendering
      ctx.save()
      x = @pos.x-@frame
      y = @pos.y-@frame
      #@draw_frame(ctx)
      ctx.drawImage(@buffer, x, y)
      ctx.restore()
    else
      @render ctx, 0

  ### draws a frame around the buffered image for analysis ###
  draw_frame: (ctx) ->
    x = @pos.x-@frame
    y = @pos.y-@frame

    ctx.beginPath()
    ctx.moveTo x, y
    ctx.lineTo x, @frame*2+y
    ctx.lineTo @frame*2+x, @frame*2+y
    ctx.lineTo @frame*2+x, y
    ctx.lineTo x, y
    ctx.stroke()
    ctx.closePath()
    
  ### Renders the shape into a buffer ###
  pre_render: (ctx) ->
    @buffer = document.createElement('canvas')
    @buffer.width = @buffer.height = @frame*2
    b_ctx = @buffer.getContext('2d')
    @render b_ctx

  ## actual painting routines
  draw_join: (ctx, partner) ->
    pos = @naub.physics.pos
    pos2 = partner.physics.pos

    # joins getting thinner by stretching
    diff = pos2.Copy()
    diff.Subtract(pos)
    l = diff.Length()
    kd = @naub.physics.keep_distance
    fiber = 10 # strength of join material ( the higher the less a join will be affected by stretching )
    stretch = (kd + fiber) / (l + fiber)
    #@join_style.fill[3] = stretch

    ctx.save()
    ctx.strokeStyle = @color_to_rgba @join_style.fill

    ctx.beginPath()
    ctx.moveTo pos.x, pos.y
    ctx.lineTo pos2.x, pos2.y
    ctx.lineWidth =  (@join_style.width * stretch)
    ctx.lineCap = "round"
    ctx.stroke()
    ctx.closePath()
    ctx.restore()




  ### animates the destruction of a naub ###
  destroy: (callback) ->
    @life_rendering = true
    shrink = =>
      @size *= 0.6
      @join_style.width *= 0.6
      @join_style.fill[3] *= 0.6
      @style.fill[3] *= 0.6
      if @size <= 0.1
        clearInterval @loop
        callback.call()

    @loop = setInterval shrink, 40



  ### utils ###
  color_to_rgba: (color,shift = 0) =>
    r = Math.round((color[0] + shift/10))
    g = Math.round((color[1] + shift/10))
    b = Math.round((color[2] + shift/10))
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"

  ## colors the shape randomly and returns color id for comparison
  random_palette_color: ->
    palette = Naubino.colors
    id = Math.round(Math.random() * (palette.length-1))
    pick = palette[id]
    @style.fill = [pick[0],pick[1],pick[2], 1]# TODO automatically assume 1 if alpha is unset (pick[3])
    id
    
  ## colors the shape randomly and returns color id for comparison
  random_color: ->
    r = Math.random()
    g = Math.random()
    b = Math.random()
    @style.fill = [r,g,b,1]
    return -1
