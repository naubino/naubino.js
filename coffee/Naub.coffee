# a Naub is everything in the game that you can move around
# Naubs can be joined under certain circumstances 
# Naubs can be given shapes 
# @param layer [Layer] the layer on which to draw
# @param color_id [int] representing the color from color palett, also neccessary for joining
# @param size [int] size, what else
define -> class Naub
  constructor: (@layer, @color_id = null, @size = Naubino.settings.naub.size) ->
    #@physics = new PhysicsModel this
   
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

    #@update() #renders it for the first time

  setup_physics: ->
    # this is redundant - just in case the the shapes don't do this
    @constraints = []

    @radius = @size/2
    @width  = @size * 0.9
    @height = @size * 0.9
    @friction = Naubino.settings.naub.slick
    @elasticity = Naubino.settings.naub.elasticity

    #this part will be adjusted by shape
    @momentum = cp.momentForCircle( Naubino.settings.naub.mass, @radius, @radius, cp.vzero)
    @physical_body = new cp.Body( Naubino.settings.naub.mass, @momentum )
    @physical_body.setAngle( 0 ) # remember to set position
    @physical_shape = new cp.CircleShape( @physical_body, @radius , cp.vzero )
    @physical_shape.setElasticity @elasticity
    @physical_shape.setFriction @friction
    @physical_shape.setFriction @friction

    #@watch_for_walls()

  watch_for_walls: ->
    @physical_shape.group = 1
    @check_group = setInterval (=>
      if @layer.point_in_field @physical_body.p
        clearInterval @check_group
        setTimeout (=> @physical_shape.group = 0),1000

    ), 10

  isHit: (pos) ->
    s = @shapes[0]
    s.isHit(@ctx, pos)

  # Returns the area value of the first shape that implements it,
  area: ->
    r = @size/2
    Math.floor r*r*Math.PI

  # Either renders shapes or draws buffer 
  #
  # @param ctx [canvas.context] context of the target layer
  # set @life_rendering to true if you want to have an animated naub
  # either renders live or draws pre_rendered image
  draw: () ->
    pos = if @physical_body then @physical_body.p else @pos
    unless Naubino.settings.graphics.updating or @life_rendering
      @ctx.save()
      x = pos.x-@frame
      y = pos.y-@frame
      #@draw_frame(ctx)
      @ctx.drawImage(@buffer, x, y)
      @ctx.restore()
    else # render life
      @render(@ctx, pos.x,pos.y)


  # Renders the shape into a buffer
  update: () ->
    @buffer = document.createElement('canvas')
    @buffer.width = @buffer.height = @frame *2
    b_ctx = @buffer.getContext('2d')
    @render b_ctx, @frame, @frame


  # Executes the render method of all shapes
  render: (ctx,x,y) ->
    for shape in @shapes
      shape.render(ctx,x,y)


  # adds a shape and runs its setup
  add_shape: (shape)->
    shape.setup this
    @shapes.push shape
    @update()

  # adds shapes and runs setups
  add_shapes: (shapes)->
    for shape in shapes
      @add_shape shape

  update_shapes: ->
    for shape in @shapes
      shape.setup this


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
    pos = if @physical_body then @physical_body.p else @pos
    pos2 = if partner.physical_body then partner.physical_body.p else partner.pos
    # joins getting thinner by stretching
    diff = pos2.Copy()
    diff.sub(pos)
    l = diff.Length()
    fiber = 10 # strength of join material ( the higher the less a join will be affected by stretching )
    stretch = (30 + fiber) / (l + fiber)
    stretch = Math.round((stretch)*10)/10 # rounding
    #@join_style.fill[3] = stretch
    stretched_width = @join_style.width * stretch
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



  # makes a naub clickable and joinable again
  disable: ->
    @disabled = true
    @update()


  # makes a naub unclickable and joinable
  enable: ->
    @disabled = false
    @update()


  # change fill to gray
  grey_out: -> @style.fill = [100,100,100,1]

  # sets color from @color_id
  recolor: -> @style.fill = Naubino.colors[@color_id]

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





  attach_to: ( center ) ->
    unless @centerjoin?
      # TODO implement this
    else
      console.warn "object is already attached to a point"

  attracted_to: ( center ) ->
    unless @centerjoin?
      #restLength, stiffness, damping
      rstl = Naubino.settings.physics.center_join.restLength
      stfs =  Naubino.settings.physics.center_join.stiffness
      dmpg =  Naubino.settings.physics.center_join.damping
      @centerjoin = new cp.DampedSpring( @physical_body, @layer.space.staticBody, cp.vzero, center, rstl, stfs, dmpg)
      @layer.space.addConstraint( @centerjoin )
      @constraints.push @centerjoin
    else
      console.warn "object is already attached to a point"


  # do things a naub is supposed to do
  join_with: (other) ->
    #restLength, stiffness, damping
    minlen = Naubino.settings.naub.min_join_len * @size
    maxlen = Naubino.settings.naub.max_join_len * @size
    joint = new cp.DampedSpring( @physical_body, other.physical_body, cp.vzero, cp.vzero, minlen, 4, 30)
    joint2 = new cp.SlideJoint( @physical_body, other.physical_body, cp.vzero, cp.vzero, minlen, maxlen)

    @layer.space.addConstraint( joint )
    @layer.space.addConstraint( joint2 )
    @constraints.push joint
    @constraints.push joint2

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
      p = @physical_body.p.Copy()
      op = other.physical_body.p.Copy()
      p.sub op
      p.Length()
    else
      NaN


  enter_field: ->
    check_in_field = ->


    setInterval (check_in_field), 10






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
