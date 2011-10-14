# controlls everything that has to do with logic and gameplay or menus
Naubino.Game = class Game extends Naubino.Layer
  
  ## get this started 
  constructor: (canvas, @graph) ->
    super(canvas)

    # display stuff
    @paused = true # changed imidiately after loading by start_timer
    @drawing = true # for debugging
    @focused_naub = null # points to the naub you click on
    @gravity = Naubino.Settings.gravity.game

    @points = -1

  

  ### the game gives it the game takes it ###
  create_some_naubs: (n = 3) ->
    for [1..n]
      {x,y} = @random_outside()
      Naubino.background.draw_marker(x,y)
      @create_naub_pair(x,y)
    for [1..n]
      {x,y} = @random_outside()
      Naubino.background.draw_marker(x,y)
      @create_naub_triple(x,y)

  create_naub: (x=@center.x, y=@center.y) ->
      naub_a = new Naubino.Naub this
      @add_object naub_a
      naub_a.shape.pre_render() # again just to get the numbers
      naub_a.physics.pos.Set x, y

  create_naub_pair: (x, y) ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this

      @add_object naub_a
      @add_object naub_b
      naub_a.shape.pre_render() # again just to get the numbers
      naub_b.shape.pre_render() # again just to get the numbers

      dir = Math.random() * Math.PI

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x, y

      naub_a.physics.pos.AddPolar(dir, 15)
      naub_b.physics.pos.AddPolar(dir, -15)

      naub_a.join_with naub_b

  create_naub_triple: (x, y) ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this
      naub_c = new Naubino.Naub this

      @add_object naub_a
      @add_object naub_b
      @add_object naub_c
      naub_a.shape.pre_render() # again just to get the numbers
      naub_b.shape.pre_render() # again just to get the numbers
      naub_c.shape.pre_render() # again just to get the numbers

      dir = Math.random() * Math.PI

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x, y
      naub_c.physics.pos.Set x, y

      naub_a.physics.pos.AddPolar(dir, 30)
      naub_c.physics.pos.AddPolar(dir, -30)

      naub_a.join_with naub_b
      naub_b.join_with naub_c

  toggle_numbers: () ->
    unless @show_numbers?
      @show_numbers = true
    else @show_numbers = not @show_numbers
    for id, naub of @objs
      naub.content = if @show_numbers then naub.shape.draw_number else null
      naub.shape.pre_render()



  # produces a random set of coordinates outside the field
  random_outside: ->
    offset = 100
    seed = Math.round (Math.random() * 3)+1
    switch seed
      when 1
        x = @width + offset
        y = @height * Math.random()
      when 2
        x = @width  * Math.random()
        y = @height + offset
      when 3
        x = 0 - offset
        y = @height * Math.random()
      when 4
        x = @width * Math.random()
        y = 0 - offset
    {x,y}

  count_basket: ->
    count = []
    if @basket_size?
      for id, naub of @objs
        diff = @center.Copy()
        diff.Subtract naub.physics.pos
        if diff.Length() < @basket_size - naub.size/2
          count.push naub.number
    count


  destroy_naubs: (list)->
    for naub in list
      @get_object(naub).disable()

    i = 0
    one_after_another= =>
      if i < list.length
        @get_object(list[i]).destroy()
        i++
      setTimeout one_after_another, 40
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
      for id, other of  @objs
        if (@focused_naub.distance_to other) < (@focused_naub.size+10)
          @focused_naub.check_joining(other)
          break

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

