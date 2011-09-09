# controlls everything that has to do with logic and gameplay or menus
Naubino.Game = class Game
  
  ## get this started 
  constructor: (@canvas, @keybindings) ->
    # TODO Exchangeable display class
    @paused = true # TODO make game.pause make sense
    @drawing = true
    @world = new Naubino.World this
    @graph = new Naubino.Graph
    @context = @canvas.getContext('2d')
    @focused_naub = null

    @settings = Naubino.Settings
    @pre_render = @settings.pre_rendering
    @colors = @settings.colors_output


    # fragile calibration! don't fuck it up!
    @dt = 0.03
    @interval = 0.05
    

  create_some_naubs: (n = 3) ->
    n = 5
    for [1..n]
      @create_naub_pair()
    for [1..n]
      @create_naub_triple()

  create_naub_pair: ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this

      x = Math.random() * @canvas.width
      y = Math.random() * @canvas.height

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 30, y + 30

      naub_a.join_with naub_b

  create_naub_triple: ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this
      naub_c = new Naubino.Naub this

      x = Math.random() * @canvas.width
      y = Math.random() * @canvas.height

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 30, y + 30
      naub_c.physics.pos.Set x + 60, y - 30

      naub_a.join_with naub_b
      naub_a.join_with naub_c


  destroy_naubs: (list)->
    for id in list
      @world.get_object(id).destroy()


  ## temus fugit
  start_timer: ->
    if @paused
      @loop = setInterval(@mainloop, @interval *1e3)
      @paused = false

  stop_timer: ->
    clearInterval @loop
    @paused = true
  
  pause: ->
      if @paused
        @start_timer()
      else
        @stop_timer()


  step: (dt) ->
    @world.step dt

  mainloop: ()=>
    @step(@dt)
    @keybindings.step(@dt)
    if @drawing
      @draw(@context)





  ## can I touch this?
  click: (x, y) ->
    @mousedown = true
    [@world.pointer.x, @world.pointer.y] = [x,y]
    naub = @get_naub x, y
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

  get_naub: (x, y) ->
    for id, naub of @world.objs
      if naub.isHit(x, y)
        return naub



  ## paint it naubino
  draw: (context) ->
    context.clearRect(0, 0, @canvas.width, @canvas.height)
    context.save()
    @world.draw context
    context.restore()

