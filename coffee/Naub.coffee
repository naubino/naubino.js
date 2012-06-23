# a Naub is everything in the game that you can move around
# Naubs can be joined under certain circumstances 
# Naubs can be given shapes 
# @param layer [Layer] the layer on which to draw
# @param color_id [int] representing the color from color palett, also neccessary for joining
# @param size [int] size, what else
define -> class Naub
  constructor: (@layer, @color_id = null, @size = Naubino.settings.naub.size) ->
    @shapes       = [] # shapes this naub draws in order from bottom to top
    @joins        = {} # {id: opposing naub}
    @drawing_join = {} # {id: true/false if this naub draws the join}
   
    @ctx         = @layer.ctx
    @frame       = @size*1.5 # defines buffer canvas

    @radius      = @size/2
    @width       = @size * 0.9
    @height      = @size * 0.9

    @removed     = false # soon to be deleted by game, garbage collector
    @focused     = false # currently activated by pointer
    @disabled    = false # cannot join with another
    @isClickable = yes # influences @layer.isHit()

    @life_rendering = false # if true redraw on each frame
    @color_id       = @random_palette_color() unless @color_id?  # unless a color_id has been give pick a randome color
    @setup_style()



  # sets opacity
  # @param alpha (int) value between 0 and 1
  set_opacity: (value) -> @style.fill[3] = value

  # sets up the style - used by all shapes
  setup_style: ->
    @style = {
      fill: [0,0,0,1]
      scale: 1
      border_width: 0
      text_color: "white"
    }
    @join_style = {
      fill: [0,0,0,1]
      width: 6
    }

    palette = Naubino.colors()
    pick = palette[@color_id]
    if pick?
      @style.fill = [ pick[0], pick[1], pick[2], pick[3] ]
    else
      @style.fill = [0,0,0, 0.5]
      console.warn @color_id, "not found"

  # colors the shape randomly and returns color id for comparison
  random_color: ->
    r = Math.random()
    g = Math.random()
    b = Math.random()
    @style.fill = [r,g,b,1]
    return -1

  # colors the shape randomly and returns color id for comparison
  random_palette_color: ->
    palette = Naubino.colors()
    id = Math.round(Math.random() * (palette.length-1))

  setup_physics: ->
    # this is redundant - just in case the the shapes don't do this
    @constraints = {}

    @friction   = Naubino.settings.naub.friction
    @elasticity = Naubino.settings.naub.elasticity

    #this part will be adjusted by shape
    @momentum = cp.momentForCircle( Naubino.settings.naub.mass, @radius, @radius, cp.vzero)
    @physical_body = new cp.Body( Naubino.settings.naub.mass, @momentum )
    @physical_body.name = "naub"
    @physical_body.setAngle( 0 ) # remember to set position
    @physical_shape = new cp.CircleShape( @physical_body, @radius , cp.vzero )
    @physical_shape.setElasticity @elasticity
    @physical_shape.setFriction @friction
    @physical_shape.setFriction @friction


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
      shape.draw(ctx,x,y)


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

  add_filter: (string) ->
    @style.filters = [] unless @style.filters?

    if string not in @style.filters
      @style.filters.push string

  remove_filter: (string) ->
    if @style.filters?
      i = @style.filters.indexOf string
      @style.filters.splice(i,1) if i  >= 0
      return


  # change fill to gray
  grey_out: ->
    @style.fill = [100,100,100,1]
    @update()

  # sets color from @color_id
  recolor: ->
    @setup_style()
    @update()



  # runs draw_join on all partners, if this naub is the one drawing the join
  # Otherwise the partner will draw the join.
  draw_joins: (context) =>
    # drawing joins
    for id, partner of @joins
      if @drawing_join[id]
        @draw_join context, partner, id
    return


  # Renders join between this naub and the partner
  # @param ctx [canvas.context] context of the target layer
  # @param partner [naub] target naub
  draw_join: (ctx, partner,id) ->
    pos = if @physical_body then @physical_body.p else @pos
    pos2 = if partner.physical_body then partner.physical_body.p else partner.pos
    # joins getting thinner by stretching
    diff = pos2.Copy()
    diff.sub(pos)
    l = diff.Length()
    fiber = 10 # strength of join material ( the higher the less a join will be affected by stretching )
    stretch = (75 ) / (l + 10)
    #stretch = Math.round((stretch)*10)/10 # rounding
    #@join_style.fill[3] = stretch
    stretched_width = @join_style.width * stretch
    ctx.save()
    ctx.globalCompositeOperation = "destination-over"
    ctx.strokeStyle = Util.color_to_rgba @join_style.fill
    ctx.beginPath()
    ctx.moveTo pos.x, pos.y
    ctx.lineTo pos2.x, pos2.y
    ctx.lineWidth = stretched_width
    ctx.lineCap = "round"
    ctx.stroke()
    ctx.closePath()
    ctx.restore()

  # makes a naub clickable and joinable again
  disable: -> @disabled = true


  # makes a naub unclickable and joinable
  enable: -> @disabled = false

  # removes the reference to this naub from all its partners
  remove: =>
    for id, naub of @joins
      @split_join id
    @removed = true

  split_join: (id) ->
    if id of @joins
      partner = @joins[id]
      @layer.graph.remove_join id
      delete partner.joins[id]
      delete @joins[id]
      if @constraints[id]?
        for con in @constraints[id]
          @layer.space.removeConstraint con


  # the amount of points the user is awarded if this naub is included in a cycle
  # 1 for "normal" naub
  # >1 for "bonus" naubs
  points_on_destroy: -> 1
    
  # animated remove with disabling  
  destroy: (is_last = false) ->
    duration = 270
    unless is_last
      for id, partner of @joins
        @drawing_join[id] = true
        partner.drawing_join[id] = false

    @disable()
    @life_rendering = on

    #@shapes[0].destroy_animation(duration) # when this one is done the naub is removed
    setTimeout (=> @remove()), duration

    @animation(@shrink,duration)

    for shape in @shapes[1..]
      shape.destroy_animation() # these are just for fun

    @layer.naub_destroyed.dispatch(@number)



  animation_pulse: ->
    @life_rendering = on
    @animation @pulse

  pulse: (dt) =>
    @style.scale = 1 +  Math.sin(3* Math.PI * dt)*0.2

  shrink: (dt) =>
    @style.scale = 1.1-dt
    @style.fill[3]= 1.1-dt
    @join_style.width *= 0.3
    @join_style.fill[3]= 1.1-dt

  animation: (animation, duration = 1000) ->
    interval = 50
    duration = duration/interval
    if typeof animation == 'function'
      animation_dt = 0
      i = setInterval (
        =>
          if animation_dt < duration
            animation(++animation_dt/duration)
          else
            clearInterval i

      ), interval



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
      @centerjoin.centerjoin = true
      @layer.space.addConstraint( @centerjoin )
      @constraints['center'] = @centerjoin
    else
      console.warn "object is already attached to a point"


  # do things a naub is supposed to do
  join_with: (other) ->
    if typeof other == 'number'
      other = @layer.get_object other

    if other? and not @is_joined_with other
      join = @layer.graph.add_join this, other # returns the id of this join in the graph

      #restLength, stiffness, damping
      minlen = Naubino.settings.naub.min_join_len * @size
      maxlen = Naubino.settings.naub.max_join_len * @size

      joint = new cp.DampedSpring( @physical_body, other.physical_body, cp.vzero, cp.vzero, minlen, 10, 30)
      joint.name = "DampedSpring"
      @layer.space.addConstraint( joint )

      joint2 = new cp.SlideJoint( @physical_body, other.physical_body, cp.vzero, cp.vzero, minlen, maxlen)
      joint2.name = "SlideJoint"
      @layer.space.addConstraint( joint2 )

      @constraints[join] = []
      #@constraints[join].push joint
      @constraints[join].push joint2

      @joins[join]      = other
      other.joins[join] = this

      @drawing_join[join]      = true
      other.drawing_join[join] = false

      @layer.naub_joined.dispatch() if @layer.naub_joined?
      join
    else
      -1


  # the 'other' naub takes my place 
  replace_with: (other) ->
    for id, naub of @joins
      if naub.constraints[id]?
        for c in naub.constraints[id]
          @layer.space.removeConstraint c

      other.join_with(naub)
      delete naub.joins[id]
      @layer.graph.remove_join id


    @layer.unfocus()

    p = other.physical_body.p
    p2 = @physical_body.p
    other.physical_body.p = cp.v.lerp(p, p2, 0.5)

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

    for n in @layer.graph.tree(@number)
      naub = @layer.get_object n
      naub.add_filter "draw_gradient"
      naub.update()

    @onfocus()
    @layer.naub_focused.dispatch(@)

  unfocus: ->
    @focused = false

    #for n in @layer.graph.tree(@number)
    #  naub = @layer.get_object n
    @layer.for_each (naub) ->
      naub.remove_filter "draw_gradient"
      naub.update()

    @onclick()
    @layer.naub_unfocused.dispatch(@)

