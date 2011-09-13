# controlls everything that has to do with logic and gameplay or menus
Naubino.Game = class Game
  
  ## get this started 
  constructor: () ->
    @settings = Naubino.Settings
    @foreground = Naubino.foreground
    @background = Naubino.background
    @keybindings = Naubino.keybindings
    @context = @foreground.getContext('2d')
    @world = new Naubino.World this
    @graph = new Naubino.Graph

    @draw_background (@background.getContext('2d'))

    # TODO Exchangeable display class
    @paused = true # changed imidiately after loading by start_timer
    @drawing = true # for debugging
    @focused_naub = null # points to the naub you click on

    @pre_render = @settings.pre_rendering
    @colors = @settings.colors_output

    # fragile calibration! don't fuck it up!
    @fps = 1000 / 40
    @dt = @fps/1500
    




  ### the game gives it the game takes it ###
  create_some_naubs: (n = 3) ->
    n = 5
    for [1..n]
      @create_naub_pair()
    for [1..n]
      @create_naub_triple()

  create_naub_pair: ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this

      x = Math.random() * @foreground.width
      y = Math.random() * @foreground.height

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 30, y + 30

      naub_a.join_with naub_b

  create_naub_triple: ->
      naub_a = new Naubino.Naub this
      naub_b = new Naubino.Naub this
      naub_c = new Naubino.Naub this

      x = Math.random() * @foreground.width
      y = Math.random() * @foreground.height

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


  step: (dt) ->
    @world.step dt

  mainloop: ()=>
    @step(@dt)
    @keybindings.step(@dt)
    if @drawing
      @draw_foreground(@context)





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
  draw_foreground: (context) ->
    context.clearRect(0, 0, @foreground.width, @foreground.height)
    context.save()
    @world.draw context
    context.restore()

    #TODO have somebody else do this
  draw_background: (context) ->
    width = Naubino.foreground.width
    height = Naubino.foreground.height
    centerX = width/2
    centerY = height/2

    context.clearRect(0, 0, @foreground.width, @foreground.height)
    context.save()
    context.arc centerX, centerY, 160, 0, Math.PI*2, false

    context.lineWidth = 5
    context.strokeStyle = "black"
    context.stroke()
    context.restore()
    
