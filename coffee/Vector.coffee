class Naubino.Vector
  ### this is loosly based on b2Vec2, but its in coffee :D ###
  constructor: (@x, @y) ->

  set: (@x, @y) ->
    return this

  setZero: ->
    @x = @y = 0.0
    return this

  setV: (v) ->
    {@x,@y} = v
    return this

  negative: ->
    new Vector(-@x, -@y)

  copy: ->
    new Vector(@x, @y)

  add: (v) ->
    @x += v.x
    @y += v.y
    console.log @x, @y
    return this

  addC: (x, y) ->
    return @add {x, y}

  addPolar: (dir, len) ->
    @x += Math.cos(dir) * len
    @y += Math.sin(dir) * len
    return this

  subtract: (v) ->
    @x -= v.x
    @y -= v.y
    return this

  multiply: (a) ->
    @x *= a
    @y *= a
    return this

  crossVF: (s) ->
    tx = @x
    @x = s * @y
    @y = -s * tx
    return this
 
  crossFV: (s) ->
    tx = @x
    @x = -s * @y
    @y = s * tx
    return this
 
  minV: (b) ->
    @x = if @x < b.x then @x else b.x
    @y = if @y < b.y then @y else b.y
    return this
 
  maxV: ->
    @x = if @x > b.x then @x else b.x
    @y = if @y > b.y then @y else b.y
    return this

  abs: ->
    @x = Math.abs @x
    @y = Math.abs @y
    return this
 
  length: ->
    Math.sqrt(@x * @x + @y * @y)
 
  length2: ->
    @x * @x + @y * @y
 
  normalize: ->
    length = @length()
    if length < Number.MIN_VALUE
      return 0.0
    invLength = 1.0 / length
    @x *= length
    @y *= length

    return length

  isValid : ->
    b2Math.b2IsValid(@x) and b2Math.b2IsValid(@y)
 



