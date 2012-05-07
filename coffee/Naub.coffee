# a Naub is everything in the game that you can move around
# Naubs can be joined under certain circumstances 
# Naubs can be given shapes 
# @param layer [Layer] the layer on which to draw
# @param color_id [int] representing the color from color palett, also neccessary for joining
# @param size [int] size, what else
define ["PhysicsModel"], (PhysicsModel) -> class Naub
  constructor: (@layer, @color_id = null, @size = Naubino.settings.naub.size) ->
    #@physics = new PhysicsModel this
   
    # gravity center
    #@physics.attracted_to = new cp.v @layer.center.x,@layer.center.y

    @ctx = @layer.ctx
    @frame = @size*1.5 # defines buffer canvas

    @color_id = @random_palette_color() unless @color_id?  # unless a color_id has been give pick a randome color
    @life_rendering = false # if true redraw on each frame

    @removed = false # soon to be deleted by game, garbage collector
    @focused = false # currently activated by pointer
    @disabled = false # cannot join with another
    @isClickable = yes # influences @layer.isHit()

    @shapes = [] # shapes this naub draws in order from bottom to top
    @joins = {} # {id: opposing naub}
    @drawing_join = {} # {id: true/false if this naub draws the join}
    @join_style = { fill: [0,0,0,1], width: 6 }

    @update() #renders it for the first time

    #
    #chipmunk
    @radius = @size # for now
    offset = cp.v(0,0)
    mass = 1
    momentum = cp.momentForCircle( mass, 0, @radius, offset )
    @physical_body = new cp.Body( mass, momentum )
    @physical_body.setAngle( 0 ) # remember to set position

    @physical_shape = new cp.CircleShape( @physical_body, @radius , offset )
    @physical_shape.setElasticity 0
    @physical_shape.setFriction 0.7





  # Either renders shapes or draws buffer 
  #
  # @param ctx [canvas.context] context of the target layer
  # set @life_rendering to true if you want to have an animated naub
  # either renders live or draws pre_rendered image
  draw: (ctx) ->
    #chipmunk test
    cpos = @physical_body.p
    @draw_point ctx, cpos.x, cpos.y
    

    pos = @physical_body.p
    unless Naubino.settings.graphics.updating or @life_rendering
      ctx.save()
      x = pos.x-@frame
      y = pos.y-@frame
      #@draw_frame(ctx)
      @ctx.drawImage(@buffer, x, y)
      @ctx.restore()
    else # render life
      @render(@ctx, pos.x,pos.y)

  draw_point: (ctx, x, y, color = "black") ->
    ctx.beginPath()
    ctx.arc(x, y, 4, 0, 2 * Math.PI, false)
    ctx.arc(x, y, 1, 0, 2 * Math.PI, false)
    ctx.lineWidth = 1
    ctx.strokeStyle = color
    ctx.stroke()
    ctx.closePath()

    
  # Renders the shape into a buffer
  update: () ->
    @buffer = document.createElement('canvas')
    @buffer.width = @buffer.height = @frame *2
    b_ctx = @buffer.getContext('2d')
    @render b_ctx, @frame, @frame

  # adjusts size and everything that is affected by it
  resize: (size = null) ->
    @size = size ? Naubino.settings.naub.size
    @frame = @size*1.5 # defines buffer canvas
    { pos, vel, force, attracted_to } = @physics
    @physics = new PhysicsModel this
    Util.extend @physics, { pos, vel, force, attracted_to }
    @update()


  # Executes the render method of all shapes
  render: (ctx,x,y) ->
    for shape in @shapes
      shape.render(ctx,x,y)

  # adds a shape and runs its setup
  add_shape: (shape)->
    shape.setup this
    @shapes.push shape
    @update()

  update_shapes: ->
    for shape in @shapes
      shape.setup this

  # Returns the area value of the first shape that implements it,
  area: ->
    r = @size
    Math.floor r*r*Math.PI

  # runs draw_join on all partners, if this naub is the one drawing the join
  # Otherwise the partner will draw the join.
  draw_joins: (context) =>
    # drawing joins
    for id, partner of @joins
      if @drawing_join[id]
        @draw_join context, partner
    return


  # Renders join between this naub and the partner
  # @param ctx [canvas.context] context of the target layer
  # @param partner [naub] target naub
  draw_join: (ctx, partner) ->
    pos = @physical_body.p
    pos2 = partner.physical_body.p

    # TODO auskommentiert
    # # joins getting thinner by stretching
    # diff = pos2.Copy()
    # diff.Subtract(pos)
    # l = diff.Length()
    # m = @physics.margin*25
    # fiber = 10 # strength of join material ( the higher the less a join will be affected by stretching )
    # stretch = (m + fiber) / (l + fiber)
    # stretch = Math.round((stretch)*10)/10 # rounding
    # #@join_style.fill[3] = stretch
    # stretched_width = @join_style.width * stretch

    stretched_width = 3
    ctx.save()
    ctx.strokeStyle = @color_to_rgba @join_style.fill
    try
      ctx.beginPath()
      ctx.moveTo pos.x, pos.y
      ctx.lineTo pos2.x, pos2.y
      ctx.lineWidth = stretched_width
      ctx.lineCap = "round"
      ctx.stroke()
      ctx.closePath()
      ctx.restore()
    catch e
      #console.log [pos.x, pos.y]
      @layer.menu_pause.dispatch()



  ## organisation
  step: (dt) -> #@physics.step dt







  # makes a naub clickable and joinable again
  disable: ->
    @disabled = true
    @update()

  # makes a naub unclickable and joinable
  enable: ->
    @disabled = false
    @update()

  # change fill to gray
  grey_out: ->
    @style.fill = [100,100,100,1]

  # sets color from @color_id
  recolor: ->
    @style.fill = Naubino.colors[@color_id]

  # removes the reference to this naub from all its partners
  remove: =>
    @removed = true
    for id, naub of @joins
      delete naub.joins[id]
      @layer.graph.remove_join id


  # animated remove with disabling  
  destroy: ->
    for id, partner of @joins
      @drawing_join[id] = true
      partner.drawing_join[id] = false
    @destroying = true
    @shapes[0].destroy_animation(@remove) # when this one is done the naub is removed
    for shape in @shapes[1..]
      shape.destroy_animation() # these are just for fun
    @layer.naub_destroyed.dispatch(@number)








  # do things a naub is supposed to do
  join_with: (other) ->
    join = @layer.graph.add_join this, other # returns the id of this join in the graph
    @joins[join] = other
    @drawing_join[join] = true
    other.joins[join] = this
    other.drawing_join[join] = false
    @layer.naub_joined.dispatch() if @layer.naub_joined?
    join


  # the 'other' naub takes my place 
  replace_with: (other) ->
    remove_joins = for id, naub of @joins
      other.join_with(naub)
      delete naub.joins[id]
      @layer.graph.remove_join id
    @layer.unfocus()
    @remove()
    @layer.naub_replaced.dispatch(other.number)
    return 42

  # checks whether naub shares a common partner with other naub
  # prohibits folding of pairs
  close_related: (other)->
    naub_partners = (partner.number for id, partner of @joins)
    other_partners = (partner.number for id, partner of other.joins)
    close_related = naub_partners.some (x) -> x in other_partners # "some" is standard js and means "filter"

  # is this naub not joined with any other naub?
  alone: -> Object.keys(@joins).length == 0

  # checks whether this naub wants to join with the other
  # OVERWRITE ME
  agrees_with: (other) ->
    @color_id? and @kind? and
    @color_id == other.color_id and
    @kind     == other.kind

  is_joined_with: (other) ->
    joined = false
    for id, opnaub of @joins
      if opnaub == other
        joined = true
    return joined


  # @return [array] list of all neighboring naub_ids
  joined_naubs: ->
    list = []
    for id, naub of @joins
      list.push naub.number
    @joins

  # @return [array] list of all neighboring naubs
  partners: -> x for x in @joins






  # @params other (naub) other naub
  distance_to: (other) ->
    unless other.number == @number
      { pos, vel, force } = @physics
      { pos: opos, vel: ovel, force: oforce } = other.physics
      diff = new cp.v opos.x, opos.y
      diff.Subtract(pos)
      l = diff.Length()
    else
      NaN








  # user interaction
  onclick: ->
  onfocus: ->

  focus: ->
    @focused = true
    @update()
    @onfocus()
    @layer.naub_focused.dispatch(@)

  unfocus: ->
    @focused = false
    @update()
    @onclick()
    @layer.naub_unfocused.dispatch(@)

  isHit: (x, y) ->
    s = Naubino.settings.canvas.scale
    click = new b2Vec2(x,y)
    click.Subtract(@physics.pos)
    (click.Length() < @size) and not @removed and not @disabled
  

  # utils
  color_to_rgba: (color, shift = 0) =>
    r = Math.round((color[0] + shift))
    g = Math.round((color[1] + shift))
    b = Math.round((color[2] + shift))
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"

  # colors the shape randomly and returns color id for comparison
  random_palette_color: ->
    palette = Naubino.colors
    id = Math.round(Math.random() * (palette.length-1))
