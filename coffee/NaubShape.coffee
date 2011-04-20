class NaubShape
  constructor: (naub) ->
    @naub = @naub
    @pos = naub.physics.pos
    @size = 25
    @style =
      fill: "#fff"

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
    context.fillStyle = @style['fill']
    context.fill()
    context.restore()

  toHex: (value)->
    value  = value.toString(16)
    if value.length == 1
      return "0" + value
    return value

  randomcolor: ->
    r = Math.random() * 256
    g = Math.random() * 256
    b = Math.random() * 256

    @style['fill'] = "#" + toHex(r) + toHex(g) + toHex(b)

