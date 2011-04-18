class NaubShape
  constructor: ->
    @pos = new b2Vec2(5,5)
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
    context.arc(0, 0, 15, 0, 0)
    context.closePath()
    context.fillStyle = "#ffaaaa"
    context.fill()
    context.restore()

