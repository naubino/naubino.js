class Naubino.Naub
  constructor: (@layer, @color_id = null, @size = 14) ->
    @physics = new Naubino.PhysicsModel this
    @shape = new Naubino.Ball this

    @content = null
    unless @color_id?
      @color_id = @shape.random_palette_color()
    else
      @shape.set_color_id @color_id

    @physics.attracted_to = @layer.center.Copy() # gravity center

    @removed = false # soon to be deleted by game
    @focused = false # currently activated by pointer
    @disabled = false # cannot join with another

    @joins = {} # {id: opposing naub}
    @drawing_join = {} # {id: true/false if this naub draws the join}
    @shape.pre_render()
    @isClickable = yes



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


  ## organisation ###
  step: (dt) =>
    @physics.step dt


  ### makes a naub unclickable and joinable ###
  enable: ->
    @disabled = false
    @shape.pre_render()
    
  disable: ->
    @disabled = true
    @shape.pre_render()

  grey_out: ->
    @shape.style.fill = [100,100,100,1]

  recolor: ->
    @shape.style.fill = Naubino.colors[@color_id]

  remove: =>
    @removed = true
    for id, naub of @joins
      delete naub.joins[id]
      Naubino.graph.remove_join id


  ### animated remove with disabling   ###
  destroy: ->
    for id, partner of @joins
      @drawing_join[id] = true
      partner.drawing_join[id] = false
    @destroying = true
    @shape.destroy(@remove)
    Naubino.naub_destroyed.dispatch(@number)
    

  ### do things a naub is supposed to do ###
  join_with: (other) ->
    join = Naubino.graph.add_join this, other
    @joins[join] = other
    @drawing_join[join] = true
    other.joins[join] = this
    other.drawing_join[join] = false
    Naubino.naub_joined.dispatch()
    join


  ### the 'other' naub takes my place  ###
  replace_with: (other) ->
    remove_joins = for id, naub of @joins
      other.join_with(naub)
      delete naub.joins[id]
      Naubino.graph.remove_join id
    @layer.unfocus()
    @remove()
    console.log "replaced #{@number} with #{other.number}"
    Naubino.naub_replaced.dispatch(other.number)
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


  distance_to: (other) ->
    unless other.number == @number
      { pos, vel, force } = @physics
      { pos: opos, vel: ovel, force: oforce } = other.physics

      diff = opos.Copy()
      diff.Subtract(pos)
      l = diff.Length()
    else
      NaN


  partners: ->
    _.values @joins


  ### user interaction ###
  focus: ->
    @focused = true
    @shape.pre_render()
    @physics.friction = 10
    Naubino.naub_focused.dispatch(@)

  unfocus: ->
    @focused = false
    @shape.pre_render()
    @physics.friction = @physics.default_friction
    Naubino.naub_unfocused.dispatch(@)

  isHit: (x, y) ->
    click = new b2Vec2(x,y)
    click.Subtract(@physics.pos)
    (click.Length() < @shape.size) and not @removed and not @disabled
