class World

  # controlls everything that happens inside the field
  
  constructor: (@game) ->

    @width = @game.canvas.width
    @height = @game.canvas.height
    @field = [0, 0, @width, @height]
    @center = new b2Vec2 @field[2]/2, @field[2]/2
    @gravity = true
    @springs = true
    @rep = 3
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
      obj.draw context
      
  step: (dt) ->
    @naub_forces dt
    for obj in @objs
      obj.step dt
    for obj in @objs
      if obj.removed
        console.log obj.number
        @objs.splice(@objs.indexOf(obj),1)
    
  # TODO replace numbers by parameters in some tidy place
  naub_forces: (dt) ->
    for naub in @objs
      { pos, vel, force } = naub.physics
      
      # move to center
      if not naub.focused
        if @gravity # debug hook
          v = @center.Copy()
          v.Subtract(pos)
          v.Normalize()
          v.Multiply(6000)
          force.Add(v)
      else # except when you are held by the pointer
        v = @pointer.Copy()
        pl = v.Copy()
        pl.Subtract(pos)
        pl = pl.Length()
        v.Subtract(pos)
        v.Normalize()
        v.Multiply(2000*pl)
        force.Add(v)
      
      for other in @objs
        if (naub.number != other.number)
          { pos: opos, vel: ovel, force: oforce } = other.physics
          diff = opos.Copy()
          diff.Subtract(pos)
          if diff.Length() < 30
            if (naub.focused) &&  naub.is_joined_with(other) == false && naub.color_id == other.color_id
              console.log "joining "+ [naub.number, other.number]
              naub.replace_with(other)
            else
              console.log "not joined"

      # collide
      for [0..3]
        for other in @objs
          if (naub.number != other.number)
            { pos: opos, vel: ovel, force: oforce } = other.physics
            diff = opos.Copy()
            diff.Subtract(pos)

            l = diff.Length()

            # spring force between joined naubs
            if naub.is_joined_with(other)
              # XXX causes slight rotation when crossing to pairs
              keep_distance = 50
              v = diff.Copy()
              v.Normalize()
              v.Multiply( -0.05 * l)
              pos.Subtract(v)
              opos.Add(v)
              force.Subtract(v)
              oforce.Add(v)
            else
              keep_distance = 35

            # keep naubs from overlapping
            if (l < keep_distance) # TODO replace with obj size
              v = diff.Copy()
              v.Normalize()
              v.Multiply(keep_distance - l)
              v.Multiply(0.3)
              pos.Subtract(v)
              opos.Add(v)
              #force.Subtract(v)
              #oforce.Add(v)

