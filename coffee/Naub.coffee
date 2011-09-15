Naubino.Naub = class Naub
  constructor: () ->
    @physics = new Naubino.PhysicsModel this
    @shape = new Naubino.Ball this
    @center = new b2Vec2 0, 0

    @color_id = @shape.random_palette_color()

    @removed = false
    @focused = false

    @joins = {} # {id: opposing naub}
    @drawing_join = {} # {id: true/false if this naub draws the join}
    @shape.pre_render()


  ### drawing ###
  draw: (context)  =>
    # drawing naubs
    @shape.draw context

  draw_joins: (context) =>
    # drawing joins
    for id, partner of @joins
      if @drawing_join[id]
        @shape.draw_join context, partner
    return


  ### organisation ###
  step: (dt) =>
    @physics.step dt
    
  remove: =>
    @removed = true
    for id, naub of @joins
      delete naub.joins[id]
      Naubino.graph.remove_join id

  destroy: ->
    for id, partner of @joins
      @drawing_join[id] = true
      partner.drawing_join[id] = false
    @destroying = true
    @shape.destroy(@remove)
    Naubino.mode.naub_destroyed.dispatch(@number)

  ### do things a naub is supposed to do ###
  join_with: (other) ->
    # Check if already joined
    # check for cycle
    join = Naubino.graph.add_join this, other
    @joins[join] = other
    @drawing_join[join] = true
    other.joins[join] = this
    other.drawing_join[join] = false

  
  replace_with: (other) ->
    remove_joins = for id, naub of @joins
      other.join_with(naub)
      delete naub.joins[id]
      Naubino.graph.remove_join id
      Naubino.game.unfocus
    @remove()
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
