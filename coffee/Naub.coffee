class Naub
  constructor: (@game) ->
    @physics = new PhysicsModel
    @shape = new NaubShape this

    @removed = false
    @focused = false

    @world = @game.world
    @world.add_object this
    @joins = {} # {id: opposing naub}

  draw: (context)  =>
    # drawing joins
    for id, partner of @joins
      join = @game.graph.joins[id]
      if join[0] == @number
        @shape.draw_join context, partner

    # drawing naubs
    @shape.draw context
    
  step: (dt) =>
    @physics.step dt
    
  remove: =>
    @removed = true

  joinWith: (naub) ->
    # Check if already joined
    # check for cycle
    join = @game.graph.addJoin this, naub
    @joins[join] = naub
    naub.joins[join] = this

  isJoinedWith: (naub) ->
    joined = false
    for id, opnaub of @joins
      if opnaub == naub
        joined = true
    return joined

  joineds: ->
    list = []
    for id, naub of @joins
      list.push naub.number
    list


  isHit: (x, y) ->
    click = new b2Vec2(x,y)
    click.Subtract(@physics.pos)
    (click.Length() < @shape.size) and not @removed
