# controlls everything that has to do with logic and gameplay or menus
Naubino.Game = class Game
  
  ## get this started 
  constructor: (@world, @graph) ->
    @world.game = this

    # display stuff
    @paused = true # changed imidiately after loading by start_timer
    @drawing = true # for debugging
    @focused_naub = null # points to the naub you click on

    @points = 0

    # fragile calibration! don't fuck it up!
    @fps = 1000 / Naubino.Settings.fps
    @dt = @fps/1500
    
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

      @world.add_object naub_a
      @world.add_object naub_b

      x = Math.random() * Naubino.world_canvas.width
      y = Math.random() * Naubino.world_canvas.height

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 30, y + 30

      naub_a.join_with naub_b

  create_naub_triple: ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this
      naub_c = new Naubino.Naub this

      @world.add_object naub_a
      @world.add_object naub_b
      @world.add_object naub_c


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
        @world.get_object(list[i]).destroy()
        i++
      setTimeout one_after_another, 50
    one_after_another()



    

  ## tempus fugit
  start_timer: ->
    if @paused
      @loop = setInterval(@mainloop, @fps )
      @paused = false

  stop_timer: ->
    clearInterval @loop
    @paused = true
  
  pause: ->
      if @paused
        @start_timer()
      else
        @stop_timer()

  mainloop: ()=>
    @world.step(@dt)
    #@keybindings.step(@dt) #
    if @drawing
      @world.draw()





  ## can I touch this?
  click: (x, y) ->
    @mousedown = true
    [@world.pointer.x, @world.pointer.y] = [x,y]
    naub = @get_obj x, y
    if naub
      naub.focus()
      @focused_naub = naub

  unfocus: ->
    @mousedown = false
    if @focused_naub
      @focused_naub.unfocus()
    @focused_naub = null

  move_pointer: (x,y) ->
    if @mousedown
      [@world.pointer.x, @world.pointer.y] = [x,y]

  get_obj: (x, y) ->
    for id, naub of @world.objs
      if naub.isHit(x, y)
        return naub

