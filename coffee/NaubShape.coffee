class NaubShape
  constructor: (naub) ->
    @naub = naub
    @pos = naub.physics.pos
    @size = 14
    @style = { fill: [1,0,0,0] }

  draw: (context) =>
    context.save()
    pos = @pos
    size = @size

    context.translate(pos.x, pos.y)
    context.beginPath()
    context.arc(0, 0, size, 0, Math.PI * 2, false)
    context.closePath()
    context.fillStyle = @color_to_css(@style.fill)

    if @naub.focused
      # gradient
      gradient = context.createRadialGradient(0,0, size,0, size, size)
      gradient.addColorStop 0, @color_to_css @style.fill
      gradient.addColorStop 1, @color_to_css @style.fill, 1.7
      context.fillStyle = gradient

      # shadow
      #context.shadowColor = "#333"
      #context.shadowBlur = 5
      #context.shadowOffsetX = 2
      #context.shadowOffsetY = 2

    context.fill()

    if @naub.focused or true
      context.fillStyle = 'white'
      content.textAlign = 'center'
      context.font= '10pt Helvetica'
      context.fillText(@naub.number, -7, 5)

    context.closePath()
    context.restore()

  draw_join: (context, partner) =>
    pos = @pos
    pos2 = partner.physics.pos

    context.save()
    context.strokeStyle = "black"

    context.beginPath()
    context.moveTo pos.x, pos.y
    context.lineTo pos2.x, pos2.y
    context.lineWidth = 5
    #context.shadowColor = "#333"
    #context.shadowBlur = 5
    #context.shadowOffsetX = 2
    #context.shadowOffsetY = 2
    context.stroke()
    context.closePath()
    context.restore()

  color_to_css: (color,shift = 0) =>
    r = Math.round((color[0] + shift/10) * 255)
    g = Math.round((color[1] + shift/10) * 255)
    b = Math.round((color[2] + shift/10) * 255)
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"

  ## colors the shape randomly and returns color id for comparison
  random_palette_color: ->
    palette = @naub.game.colors
    id = Math.round(Math.random() * (palette.length-1))
    pick = palette[id]
    @style.fill = [pick[0]/255,pick[1]/255,pick[2]/255, 1]# TODO automatically assume 1 if alpha is unset (pick[3])
    id
    
  ## colors the shape randomly and returns color id for comparison
  random_color: ->
    r = Math.random()
    g = Math.random()
    b = Math.random()
    @style.fill = [r,g,b,1]
    return -1
