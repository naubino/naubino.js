Naubino.Naub = class Naub
  constructor: (@game) ->
    @physics = new Naubino.PhysicsModel
    @shape = new Naubino.NaubBall this

    @color_id = @shape.random_palette_color()

    @removed = false
    @focused = false

    @world = @game.world
    @world.add_object this

    @joins = {} # {id: opposing naub}
    @shape.pre_render()


  ### drawing ###
  draw: (context)  =>
    # drawing naubs
    @shape.draw context

  draw_joins: (context) =>
    # drawing joins
    for id, other of @joins
      join = @game.graph.joins[id]
      if join && join[0] >=  @number
        @shape.draw_join context, other
    return



  ### organisation ###
  step: (dt) =>
    @physics.step dt
    
  remove: =>
    @removed = true
    for id, naub of @joins
      delete naub.joins[id]
      @game.graph.remove_join id

  destroy: ->
    @shape.destroy(@remove)

  ### do things a naub is supposed to do ###
  join_with: (other) ->
    # Check if already joined
    # check for cycle
    join = @game.graph.add_join this, other
    @joins[join] = other
    other.joins[join] = this

  
  replace_with: (other) ->
    for id, naub of @joins
      other.join_with(naub)
      delete naub.joins[id]
      @game.graph.remove_join id
    @remove()
    @game.unfocus()
    Naubino.mode.naub_replaced.dispatch()
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

  check_joining: (other) ->
    { pos, vel, force } = @physics
    { pos: opos, vel: ovel, force: oforce } = other.physics

    diff = opos.Copy()
    diff.Subtract(pos)
    l = diff.Length()

    unless @number == other.number
      if l < @shape.size + 10

        far_enough = true
        naub_partners = for id, partner of @joins
          partner.number

        for id, partner of other.joins
          if partner.number in naub_partners
            far_enough = false

        unjoined = not @is_joined_with other
        alone = _.keys(@joins).length == 0  or  _.keys(other.joins).length == 0
        same_color = @color_id == other.color_id

        if unjoined && same_color && far_enough && not alone
          @replace_with other
        else if alone
          @join_with other

  partners: ->
    _.values @joins


  ### user interaction ###
  focus: ->
    @focused = true
    @shape.pre_render()
    @physics.friction = 9

  unfocus: ->
    @focused = false
    @shape.pre_render()
    @physics.friction = @physics.default_friction

  isHit: (x, y) ->
    click = new b2Vec2(x,y)
    click.Subtract(@physics.pos)
    (click.Length() < @shape.size) and not @removed
