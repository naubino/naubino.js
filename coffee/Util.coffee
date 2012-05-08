
#upper case function to avoid overwriting defaults
cp.Vect::Copy   = -> new cp.Vect this.x, this.y
cp.Vect::Length = -> Math.sqrt(this.x * this.x + this.y * this.y)

window.Util =
  shuffle: (a) ->
    b = a.slice()
    for x, i in b
      j = Math.floor Math.random() * b.length
      [b[i], b[j]] = [b[j], b[i]]
    b


  extend: (obj, mixin) ->
    for name, method of mixin
      console.log name
      obj[name] = method

  include: (klass, mixin) ->
    @extend klass.prototype, mixin
