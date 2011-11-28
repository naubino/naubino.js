Naubino.Naub = class Naub
  constructor: (@layer, @color_id = null) ->
    @size = 14
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
    
  enable: ->
    @disabled = false
    @shape.style.fill = Naubino.colors[@color_id]
    @shape.pre_render()

  disable: ->
    @disabled = true
    @shape.style.fill = [100,100,100,1]
    @shape.pre_render()

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
    Naubino.naub_destroyed.dispatch(@number)

  ### do things a naub is supposed to do ###
  join_with: (other) ->
    join = Naubino.graph.add_join this, other
    @joins[join] = other
    @drawing_join[join] = true
    other.joins[join] = this
    other.drawing_join[join] = false
    join

  
  replace_with: (other) ->
    remove_joins = for id, naub of @joins
      other.join_with(naub)
      delete naub.joins[id]
      Naubino.graph.remove_join id
    @layer.unfocus()
    @remove()
    console.log "replaced #{@number}"
    Naubino.naub_replaced.dispatch()
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
    unless @number == other.number
      #console.log "checking #{@number}(#{@color_id}) and #{other.number}(#{other.color_id})"
      far_enough = true
      naub_partners = for id, partner of @joins
        partner.number

      for id, partner of other.joins
        if partner.number in naub_partners
          far_enough = false

      unjoined = not @is_joined_with other
      alone = _.keys(@joins).length == 0
      other_alone = _.keys(other.joins).length == 0
      same_color = @color_id == other.color_id

      if not @disabled && unjoined && same_color && far_enough && not alone && not other_alone
        other.replace_with this
        true
      else if alone and not (other.disabled or @disabled)
        @join_with other
        true
      else
        false
    else
      false
          
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

  unfocus: ->
    @focused = false
    @shape.pre_render()
    @physics.friction = @physics.default_friction

  isHit: (x, y) ->
    click = new b2Vec2(x,y)
    click.Subtract(@physics.pos)
    (click.Length() < @shape.size) and not @removed and not @disabled
