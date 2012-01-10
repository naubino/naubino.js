###
generated using js2coffee
###
(->
  @b2Vec2 = (x, y) ->
    @x = x
    @y = y

  proto = b2Vec2::
  proto.SetZero = ->
    @x = 0.0
    @y = 0.0

  proto.Set = (x_, y_) ->
    @x = x_
    @y = y_

  proto.SetV = (v) ->
    @x = v.x
    @y = v.y

  proto.Negative = ->
    new b2Vec2(-@x, -@y)

  proto.Copy = ->
    new b2Vec2(@x, @y)

  proto.Add = (v) ->
    @x += v.x
    @y += v.y

  proto.AddC = (x, y) ->
    @x += x
    @y += y

  proto.AddPolar = (dir, len) ->
    @x += Math.cos(dir) * len
    @y += Math.sin(dir) * len

  proto.Subtract = (v) ->
    @x -= v.x
    @y -= v.y

  proto.Multiply = (a) ->
    @x *= a
    @y *= a

  proto.MulM = (A) ->
    tX = @x
    @x = A.col1.x * tX + A.col2.x * @y
    @y = A.col1.y * tX + A.col2.y * @y

  proto.MulTM = (A) ->
    tX = b2Math.b2Dot(this, A.col1)
    @y = b2Math.b2Dot(this, A.col2)
    @x = tX

  proto.CrossVF = (s) ->
    tX = @x
    @x = s * @y
    @y = -s * tX

  proto.CrossFV = (s) ->
    tX = @x
    @x = -s * @y
    @y = s * tX

  proto.MinV = (b) ->
    @x = (if @x < b.x then @x else b.x)
    @y = (if @y < b.y then @y else b.y)

  proto.MaxV = (b) ->
    @x = (if @x > b.x then @x else b.x)
    @y = (if @y > b.y then @y else b.y)

  proto.Abs = ->
    @x = Math.abs(@x)
    @y = Math.abs(@y)

  proto.Length = ->
    Math.sqrt @x * @x + @y * @y

  proto.Length2 = ->
    @x * @x + @y * @y

  proto.Normalize = ->
    length = @Length()
    return 0.0  if length < Number.MIN_VALUE
    invLength = 1.0 / length
    @x *= invLength
    @y *= invLength
    length

  proto.IsValid = ->
    b2Math.b2IsValid(@x) and b2Math.b2IsValid(@y)
)()
