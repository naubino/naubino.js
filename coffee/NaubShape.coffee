window.NaubShape = class NaubShape 
  constructor: ->
    @pos = new b2Vec2(5,5)
    @size = 5
    @style = 
      fill: ["fillme"]


  draw: (context) ->
    context.save()
    pos = @pos
    size = @size
    w = 5
    h = 5
    context.translate(pos.x, pos.y)
    context.beginPath()
    context.rect(-w / 2, -h / 2, w, h)
    context.closePath()
    context.fillStyle = "#ffaaaa"
    context.fill()
    context.restore()

