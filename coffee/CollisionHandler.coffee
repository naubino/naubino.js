define -> class CollisionHandler
  constructor: (@game) ->
	  this.a = this.b = 0

  # Collision begin event callback
  # Returning false from a begin callback causes the collision to be ignored until
  # the the separate callback is called when the objects stop colliding.
  begin: (arb, space) ->
    return true

  # Collision pre-solve event callback
  # Returning false from a pre-step callback causes the collision to be ignored until the next step.
  preSolve: (arb, space) ->
    return true

  # Collision post-solve event function callback type.
  postSolve: (arb, space) ->



  # Collision separate event function callback type.
  separate: (arb, space) ->
    if arb.a.naub_number? and arb.b.naub_number?
      {a,b} = @naubs(arb)
      @game.check_joining a,b, arb

  naub: (a)->
    @game.get_object arb.a.naub_number

  naubs: (arb)->
    a = @game.get_object arb.a.naub_number
    b = @game.get_object arb.b.naub_number
    {a,b}
