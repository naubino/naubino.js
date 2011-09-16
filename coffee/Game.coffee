# controlls everything that has to do with logic and gameplay or menus
Naubino.Game = class Game extends Naubino.Layer
  
  ## get this started 
  constructor: (canvas, @graph) ->
    super(canvas)

    # display stuff
    @paused = true # changed imidiately after loading by start_timer
    @drawing = true # for debugging
    @focused_naub = null # points to the naub you click on

    @points = 0

    
    # TODO move this to mode
    @create_some_naubs(12)
    @start_timer()


  ### the game gives it the game takes it ###
  create_some_naubs: (n = 3) ->
    n = 6
    for [1..n]
      @create_naub_pair()
    for [1..n]
      @create_naub_triple()

  create_naub_pair: ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this

      @add_object naub_a
      @add_object naub_b

      x = Math.random() * Naubino.world_canvas.width
      y = Math.random() * Naubino.world_canvas.height

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 30, y + 30

      naub_a.join_with naub_b

  create_naub_triple: ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this
      naub_c = new Naubino.Naub this

      @add_object naub_a
      @add_object naub_b
      @add_object naub_c


      x = Math.random() * Naubino.background_canvas.width
      y = Math.random() * Naubino.background_canvas.height

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 30, y + 30
      naub_c.physics.pos.Set x + 60, y - 30

      naub_a.join_with naub_b
      naub_b.join_with naub_c

  destroy_naubs: (list)->
    i = 0
    one_after_another= =>
      if i < list.length
        @get_object(list[i]).destroy()
        i++
      setTimeout one_after_another, 50
    one_after_another()



    

  ## here used to be tempus fugit





  # controlls everything that happens inside the field
  
    
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
    if @mousedown && @focused_naub
      @focused_naub.physics.follow @pointer.Copy()
      for id, obj of  @objs
        @focused_naub.check_joining obj if @focused_naub

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

