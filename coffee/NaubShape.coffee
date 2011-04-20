class NaubShape
  constructor: (physics) ->
    @pos = physics.pos
    @size = 25
    @style =
      fill: ["fillme"]

  draw: (context) ->
    context.save()
    pos = @pos
    size = @size
    w = 25
    h = 25
    context.translate(pos.x, pos.y)
    context.beginPath()
    context.arc(0, 0, 15, 0, Math.PI * 2)
    context.closePath()
    context.fillStyle = "#aaaaaa"
    context.fill()
    context.restore()

