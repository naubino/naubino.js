class World

  # controlls everything that happens inside the field
  
  constructor: (@game) ->

    @width = @game.canvas.width
    @height = @game.canvas.height
    @field = [0, 0, @width, @height]
    @center = new b2Vec2 @field[2]/2, @field[2]/2
    @gravity = true
    @pointer = @center.Copy()

    @objs = []
    @objs_count = 0

  add_object: (obj)->
    @objs_count++
    obj.number = @objs_count
    @objs.push obj

  get_object: (id)->
    @objs[id]

  remove_obj: (obj) ->
    @objs.splice(@objs.indexOf(obj),1)
    
  draw: (context) ->
    for obj in @objs
      obj.draw_joins context

    for obj in @objs
      obj.draw context
      
  step: (dt) ->
    # physics
    @naub_forces dt
    
    # check for joinings
    if @game.mousedown && @game.focused_naub
      for obj in @objs
        @check_joining @game.focused_naub, obj

    # delete objects
    for obj in @objs
      if obj.removed
        @remove_obj obj
        return 42


  check_joining: (naub, other) ->
    if naub
      { pos, vel, force } = naub.physics
      { pos: opos, vel: ovel, force: oforce } = other.physics

      diff = opos.Copy()
      diff.Subtract(pos)
      l = diff.Length()

      unless naub == other
        if l < 23
          far_enough = true
          naub_partners = for id, partner of naub.joins
            partner.number

          for id, partner of other.joins
            if partner.number in naub_partners
              far_enough = false

          unjoined = not naub.is_joined_with other
          same_color = naub.color_id == other.color_id

          if unjoined && same_color &&  far_enough
            naub.replace_with other




  # TODO replace numbers by parameters in some tidy place
  naub_forces: (dt) ->
    for naub in @objs

      # everything moves toward the middle
      @gravitate naub

      # joined naubs have spring forces 
      for other in @objs
        @join_springs naub, other
      
      # collide
      for [0..3]
        for other in @objs
          @collide naub, other
      
      # use all previously calculated forces and actually move the damn thing 
      naub.step(dt)

  # keep naubs from overlapping
  collide: (naub, other) ->
    if (naub.number != other.number)
      { pos, vel, force } = naub.physics
      { pos: opos, vel: ovel, force: oforce } = other.physics

      diff = opos.Copy()
      diff.Subtract(pos)
      l = diff.Length()

      if naub.number < other.number &&  l < 35  # TODO replace with obj size
        v = diff.Copy()
        v.Normalize()
        v.Multiply(35 - l)
        v.Multiply(0.3)
        pos.Subtract(v)
        opos.Add(v)
        force.Subtract(v)
        oforce.Add(v)

  gravitate: (naub) ->
    { pos, vel, force } = naub.physics
    if not naub.focused
      if @gravity # debug hook
        v = @center.Copy()
        v.Subtract(pos)
        v.Normalize()
        v.Multiply(25)
        force.Add(v)

    else # except when you are held by the pointer
      v = @pointer.Copy()
      pl = v.Copy()
      pl.Subtract(pos)
      pl = pl.Length()

      v.Subtract(pos)
      v.Normalize()
      v.Multiply(30*pl)
      force.Add(v)

      
  # spring force between joined naubs
  join_springs: (naub, other) ->
    # XXX causes slight rotation when crossing to pairs
    if naub.is_joined_with(other)
      { pos, vel, force } = naub.physics
      { pos: opos, vel: ovel, force: oforce } = other.physics

      diff = opos.Copy()
      diff.Subtract(pos)
      l = diff.Length()
      v = diff.Copy()

      v.Normalize()
      v.Multiply( -1/100 * naub.physics.spring_force * l * l * l)
      force.Subtract(v)
      oforce.Add(v)

      keep_distance = 40
      if (l < keep_distance) # TODO replace with obj size
        v = diff.Copy()
        v.Normalize()
        v.Multiply(keep_distance - l)
        v.Multiply(0.3)
        pos.Subtract(v)
        opos.Add(v)
        force.Subtract(v)
        oforce.Add(v)

