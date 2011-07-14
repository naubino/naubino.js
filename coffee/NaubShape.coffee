class NaubShape
  constructor: (naub) ->
    @naub = @naub
    @pos = naub.physics.pos
    @size = 25
    @style = { fill: [1,0,0,0] }

  draw: (context) =>
    context.save()
    pos = @pos
    size = @size
    w = 25
    h = 25
    context.translate(pos.x, pos.y)
    context.beginPath()
    context.arc(0, 0, 15, 0, Math.PI * 2)
    context.closePath()
    context.fillStyle = @color_to_css(@style.fill)
    context.fill()
    context.restore()

  color_to_css: (color) =>
    r = Math.round(color[0] * 255)
    g = Math.round(color[1] * 255)
    b = Math.round(color[2] * 255)
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"

  random_color: ->
    r = Math.random()
    g = Math.random()
    b = Math.random()
    [r,g,b,1]

