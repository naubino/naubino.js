class Game

  # controlls everything that has to do with logic and gameplay or menus
  
  constructor: (@canvas, @keybindings) ->
    # TODO Exchangeable display class
    @time_factor = 1

    @world = new World this
    @graph = new Graph

    @context = @canvas.getContext('2d')

  create_some_naubs: (n = 3) ->
    for [0..n]
      @create_naub_pair()

  create_naub_pair: ->
      naub_a = new Naub this
      naub_b = new Naub this
      naub_a.shape.style.fill = naub_a.shape.random_color()
      naub_b.shape.style.fill = naub_b.shape.random_color()

      x = Math.random() * 600
      y = Math.random() * 400

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 30, y + 30
      naub_a.physics.vel.Set 0, 0
      naub_b.physics.vel.Set 0, 0
      naub_a.joinWith naub_b

  start_timer: ->
    @loop = setInterval(@mainloop, 0.05*1e3)

  stop_timer: ->
    clearInterval @loop

  step: (dt) ->
    @world.step dt

  click: (x, y) ->
    @getNaub x, y

  getNaub: (x, y) ->
    for naub in @world.objs
      if naub.isHit(x, y)
        console.log naub.number + " -> " + @graph.getPartner naub.joins[0], naub

  draw: (context) ->
    context.clearRect(0, 0, @canvas.width, @canvas.height)
    context.save()
    @world.draw context
    context.restore()

  mainloop: ()=>
    dt = 0.02
    @step(dt)
    @keybindings.step(dt)
    @draw(@context)
