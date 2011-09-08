class Naub
  constructor: (@game) ->
    @physics = new PhysicsModel
    @shape = new NaubShape this

    @color_id = @shape.random_palette_color()

    @removed = false
    @focused = false

    @world = @game.world
    @world.add_object this

    @joins = {} # {id: opposing naub}

  draw: (context)  =>
    # drawing naubs
    @shape.draw context

  draw_joins: (context) =>
    # drawing joins
    for id, other of @joins
      join = @game.graph.joins[id]
      if join[0] >=  @number
        @shape.draw_join context, other

  step: (dt) =>
    @physics.step dt
    
  remove: =>
    @removed = true

  ## structural functionality
  join_with: (other) ->
    # Check if already joined
    # check for cycle
    join = @game.graph.add_join this, other
    @joins[join] = other
    other.joins[join] = this

  replace_with: (other) ->
    console.log "replace: " + [@number, other.number]
    for id, naub of @joins
      other.join_with(naub)
      delete naub.joins[id]
      @game.graph.remove_join id
    @remove()
    @game.unfocus()
    return 42


  is_joined_with: (other) ->
    joined = false
    for id, opnaub of @joins
      if opnaub == other
        joined = true
    return joined

  joined_naubs: ->
    list = []
    for id, naub of @joins
      list.push naub.number
    @joins

  focus: ->
    @focused = true
    @physics.friction = 9

  unfocus: ->
    @focused = false
    @physics.friction = @physics.default_friction


  isHit: (x, y) ->
    click = new b2Vec2(x,y)
    click.Subtract(@physics.pos)
    (click.Length() < @shape.size) and not @removed
