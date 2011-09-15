Naubino.Field = Naubino.World = class World extends Naubino.Layer

  # controlls everything that happens inside the field
  
  constructor: (canvas) ->
    super(canvas)

    @pointer = @center.Copy()

    @objs = {}
    @objs_count = 0


  ### managing objects ###
  add_object: (obj)->
    obj.center = @center
    @objs_count++
    obj.number = @objs_count
    @objs[@objs_count] = obj

  get_object: (id)->
    @objs[id]


  remove_obj: (id) ->
    delete @objs[id]
    
  draw:  ->
    @ctx.clearRect(0, 0, Naubino.world_canvas.width, Naubino.world_canvas.height)
    @ctx.save()
    for id, obj of @objs
      obj.draw_joins @ctx

    for id, obj of @objs
      obj.draw @ctx
    @ctx.restore()
      



  # work and have everybody else do their work as well
  step: (dt) ->
    # physics
    @naub_forces dt
    
    # check for joinings
    if @game.mousedown && @game.focused_naub
      @game.focused_naub.physics.follow @pointer.Copy()
      for id, obj of  @objs
        @game.focused_naub.check_joining obj if @game.focused_naub

    # delete objects
    for id, obj of @objs
      if obj.removed
        @remove_obj id
        return 42 # TODO found out if there is a way to have a void function?




  naub_forces: (dt) ->
    for id, naub of @objs

      # everything moves toward the middle
      naub.physics.gravitate()

      # joined naubs have spring forces 
      for id, other of naub.joins
        @join_springs naub, other
      
      # collide
      for [0..3]
        for id, other of @objs
          @collide naub, other
      
      # use all previously calculated forces and actually move the damn thing 
      naub.step(dt)



  ### collide(), gravitate(), join_springs ###

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
        v.Multiply(0.6)
        pos.Subtract(v)
        opos.Add(v)
        force.Subtract(v)
        oforce.Add(v)


      
  # spring force between joined naubs
  join_springs: (naub, other) ->
    # XXX causes slight rotation when crossing to pairs
    { pos, vel, force, keep_distance } = naub.physics
    { pos: opos, vel: ovel, force: oforce } = other.physics

    diff = opos.Copy()
    diff.Subtract(pos)
    l = diff.Length()
    v = diff.Copy()

    v.Normalize()
    v.Multiply( -1/100 * naub.physics.spring_force * l * l * l)
    force.Subtract(v)
    oforce.Add(v)

    if (l < keep_distance) # TODO replace with obj size
      v = diff.Copy()
      v.Normalize()
      v.Multiply(keep_distance - l)
      v.Multiply(0.3)
      vel.Subtract(v)
      ovel.Add(v)
      force.Subtract(v)
      oforce.Add(v)

