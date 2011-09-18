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
    @start_timer()


  ### the game gives it the game takes it ###
  create_some_naubs: (n = 3) ->
    for [1..n]
      @create_naub_pair()
    for [1..n]
      @create_naub_triple()

  create_naub_pair: ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this

      @add_object naub_a
      @add_object naub_b
      naub_a.shape.pre_render() # again just to get the numbers
      naub_b.shape.pre_render() # again just to get the numbers

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
      naub_a.shape.pre_render() # again just to get the numbers
      naub_b.shape.pre_render() # again just to get the numbers
      naub_c.shape.pre_render() # again just to get the numbers


      x = Math.random() * Naubino.background_canvas.width
      y = Math.random() * Naubino.background_canvas.height

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 30, y + 30
      naub_c.physics.pos.Set x + 60, y - 30

      naub_a.join_with naub_b
      naub_b.join_with naub_c

  destroy_naubs: (list)->
    for naub in list
      @get_object(naub).disable()

    i = 0
    one_after_another= =>
      if i < list.length
        @get_object(list[i]).destroy()
        i++
      setTimeout one_after_another, 50
    one_after_another()



    


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
        naub.physics.join_springs other
      
      # collide
      for [0..3]
        for id, other of @objs
          naub.physics.collide other
      
      # use all previously calculated forces and actually move the damn thing 
      naub.step(dt)





      
