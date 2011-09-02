class Naub
  constructor: (@game) ->
    @physics = new PhysicsModel
    @shape = new NaubShape this
    @removed = false
    @world = @game.world
    @world.add_object this
    @joins = []

  draw: (context)  =>
    # drawing joins
    for id in @joins
      join = @game.graph.joins[id]
      if join[0] == @number
        partner = @world.get_object(@game.graph.getPartner(id, @number)) #TODO simplify this
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
    @joins.push join
    naub.joins.push join

  isHit: (x, y) ->
    click = new b2Vec2(x,y)
    click.Subtract(@physics.pos)
    click.Length() < @shape.size
