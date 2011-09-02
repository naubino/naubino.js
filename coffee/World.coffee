class World

  # controlls everything that happens inside the field
  
  constructor: (@game) ->

    @width = @game.canvas.width
    @height = @game.canvas.height
    @field = [0, 0, @width, @height]
    @center = new b2Vec2 @field[2]/2, @field[2]/2

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
      @world.remove_obj(this) if obj.removed
    
  naub_forces: (dt) ->
    for naub in @objs
      { pos, vel, force } = naub.physics
      
      # move to center
      if not naub.focused
        v = @center.Copy()
        v.Subtract(pos)
        v.Normalize()
        v.Multiply(4000)
        force.Add(v)
      else
        v = @pointer.Copy()
        pl = v.Copy()
        pl.Subtract(pos)
        pl = pl.Length()
        v.Subtract(pos)
        v.Normalize()
        v.Multiply(2000*pl)
        force.Add(v)
      
      # collide
      for [0..3]
        for other in @objs
          { pos: opos, vel: ovel, force: oforce } = other.physics
          diff = opos.Copy()
          diff.Subtract(pos)

          l = diff.Length()
          if naub.isJoinedWith(other)
            keep_distance = 45

            v = diff.Copy()
            v.Normalize()
            v.Multiply( -0.1 * l)
            pos.Subtract(v)
            #opos.Subtract(v)
            #force.Subtract(v)
            #oforce.Add(v)
          else
            keep_distance = 35

          if (l < keep_distance) # TODO replace with obj size
            v = diff.Copy()
            v.Normalize()
            v.Multiply(keep_distance - l)
            v.Multiply(0.5)
            pos.Subtract(v)
            opos.Add(v)
            #force.Subtract(v)
            #oforce.Add(v)
