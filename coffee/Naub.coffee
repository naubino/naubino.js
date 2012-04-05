Naubino.Shapes = {}
class Naubino.Shape
  constructor: ->
    @style = { fill: [0,0,0,1] }

  setup: (@naub) ->
    @pos = @naub.pos
    @ctx = @naub.ctx
    @set_color_from_id @naub.color_id


  # utils
  color_to_rgba: (color, shift = 0) =>
    r = Math.round((color[0] + shift))
    g = Math.round((color[1] + shift))
    b = Math.round((color[2] + shift))
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"

  # change color
  set_color_from_id:(id)->
    palette = Naubino.colors
    pick = palette[id]
    @style.fill = [pick[0],pick[1],pick[2], 1]
    # TODO automatically assume 1 if alpha is unset (pick[3])
    id

    
  # colors the shape randomly and returns color id for comparison
  random_color: ->
    r = Math.random()
    g = Math.random()
    b = Math.random()
    @style.fill = [r,g,b,1]
    return -1

class Naubino.Shapes.Square extends Naubino.Shape

  area: ->
    @width^2


  # actual painting routines
  render: () ->
    @ctx.save()
    pos = @pos
    size= @size
    width= @size * 2

    @rot = @rot + 0.1
    @ctx.translate( x, y)
    @ctx.rotate @rot
      
    @ctx.beginPath()
    @ctx.rect(-width/2,-width/2,width,width)

    @ctx.fillStyle = @color_to_rgba(@style.fill)
    @ctx.fill()
    @ctx.closePath()


    if @content?
      @content.call(this, ctx, 0)

    @ctx.restore()

  isHit:(x,y) ->
    width = @size * 2
    @layer.ctx.beginPath()
    @layer.ctx.rect(@pos.x-width/2,@pos.y-width/2,width,width)
    @layer.ctx.closePath()
    @layer.ctx.isPointInPath(x,y)

class Naubino.Shapes.Ball extends Naubino.Shape
  area: ->
    # TODO consolder the margin of each naub
    Math.PI * size * size

  # actual painting routines
  render: (ctx, x = 42, y = x) ->
    @ctx.save()
    pos = @pos
    size= @size

    offset = 0
    @ctx.translate( x, y)
      
    @ctx.beginPath()
    @ctx.arc(offset, offset, size, 0, Math.PI * 2, false)
    @ctx.closePath()

    ## border
    #ctx.lineWidth = 2
    #ctx.stroke()

    if @focused
      # gradient
      gradient = ctx.createRadialGradient(offset, offset, size/3, offset, offset, size)
      gradient.addColorStop 0, @color_to_rgba(@style.fill, 80)
      gradient.addColorStop 1, @color_to_rgba(@style.fill, 50)
      ctx.fillStyle = gradient
    else
      @ctx.fillStyle = @color_to_rgba(@style.fill)

    # shadow
    #ctx.shadowColor = "#333"
    #ctx.shadowBlur = 3
    #ctx.shadowOffsetX = 1
    #ctx.shadowOffsetY = 1

    @ctx.fill()
    @ctx.closePath()

    if @content?
      @content.call(this, ctx, offset)

    @ctx.restore()

class Naubino.Shapes.Frame extends Naubino.Shape
  # draws a frame around the buffered image for analysis
  # @param ctx [canvas.context] context of the target layer
  render: (ctx) ->
    x = @pos.x-@frame/2
    y = @pos.y-@frame/2

    ctx.beginPath()
    ctx.moveTo x, y
    ctx.lineTo x, @frame+y
    ctx.lineTo @frame+x, @frame+y
    ctx.lineTo @frame+x, y
    ctx.lineTo x, y
    ctx.stroke()
    #ctx.fillStyle = "beige"
    #ctx.fill()
    ctx.closePath()
class Naubino.Shapes.String extends Naubino.Shape
  render: (ctx, string, color = 'white') ->
    ctx.fillStyle = color
    ctx.textAlign = 'center'
    ctx.font= "#{@size+4}px Helvetica"
    ctx.fillText(string, 0, 6)

class Naubino.Shapes.Number extends Naubino.Shape
  render: (ctx, offset = 0) ->
    @draw_string ctx, this.number


# a Naub is everything in the game that you can move around
# Naubs can be joined under certain circumstances 
# Naubs can be given shapes 
# @param layer [Layer] the layer on which to draw
# @param color_id [int] representing the color from color palett, also neccessary for joining
# @param size [int] size, what else
class Naubino.Naub
  constructor: (@layer, @color_id = null, @size = 14) ->
    @physics = new Naubino.PhysicsModel this
    @pos = @physics.pos
    @frame = @size*2.5
    @join_style = { fill: [0,0,0,1], width: 6 }
    @life_rendering = false # if true redraw on each frame
    # previous constructor of shape

    # unless a color_id has been give pick a randome color
    @color_id = @random_palette_color() unless @color_id?

    @physics.attracted_to = @layer.center.Copy() # gravity center

    @removed = false # soon to be deleted by game, garbage collector
    @focused = false # currently activated by pointer
    @disabled = false # cannot join with another
    @isClickable = yes # cannot

    @shapes = [] # shapes this naub draws in order from bottom to top

    @joins = {} # {id: opposing naub}
    @drawing_join = {} # {id: true/false if this naub draws the join}
    @update() #renders it for the first time



  # either renders live or draws updateed image
  #
  # @param ctx [canvas.context] context of the target layer
  # set @life_rendering to true if you want to have an animated naub
  draw: () ->
    if Naubino.Settings.updateing and not @life_rendering
      @ctx.save()
      x = @pos.x-@frame
      y = @pos.y-@frame
      #@draw_frame(ctx)
      @ctx.drawImage(@buffer, x, y)
      @ctx.restore()
    else
      @render()

    
  # Renders the shape into a buffer
  # @param ctx [canvas.context] context of the target layer
  update: () ->
    @buffer = document.createElement('canvas')
    @buffer.width = @buffer.height = @frame*2
    b_ctx = @buffer.getContext('2d')
    @render b_ctx, @frame, @frame

  # executes the render method of all shapes
  render: () ->
    for shape in @shapes
      shape.render()

  # adds a shape and runs its setup
  add_shape: (shape)->
    shape.setup this
    @shapes.push shape


  # actual painting routines
  # @param ctx [canvas.context] context of the target layer
  # @param partner [naub] target naub
  draw_join: (ctx, partner) ->
    pos = @physics.pos
    pos2 = partner.physics.pos

    # joins getting thinner by stretching
    diff = pos2.Copy()
    diff.Subtract(pos)
    l = diff.Length()
    kd = @physics.keep_distance
    fiber = 10 # strength of join material ( the higher the less a join will be affected by stretching )
    stretch = Math.round(((kd + fiber) / (l + fiber))*10)/10
    #@join_style.fill[3] = stretch
    stretched_width = @join_style.width * stretch

    ctx.save()
    ctx.strokeStyle = @color_to_rgba @join_style.fill
    try
      ctx.beginPath()
      ctx.moveTo pos.x, pos.y
      ctx.lineTo pos2.x, pos2.y
      ctx.lineWidth =  stretched_width
      ctx.lineCap = "round"
      ctx.stroke()
      ctx.closePath()
      ctx.restore()
    catch e
      console.log [pos.x, pos.y]
      Naubino.menu_pause.dispatch()



  draw_joins: (context) =>
    # drawing joins
    for id, partner of @joins
      if @drawing_join[id]
        @draw_join context, partner
    return


  ## organisation
  step: (dt) =>
    @physics.step dt







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
      Naubino.graph.remove_join id


  # animated remove with disabling  
  destroy: ->
    for id, partner of @joins
      @drawing_join[id] = true
      partner.drawing_join[id] = false
    @destroying = true
    @destroy_animation(@remove)
    Naubino.naub_destroyed.dispatch(@number)


  # animates the destruction of a naub
  # @params callback [function] function that will be called after the animation has ended
  destroy_animation: (callback) ->
    @life_rendering = true
    shrink = =>
      @size *= 0.6
      @join_style.width *= 0.6
      @join_style.fill[3] *= 0.6
      @style.fill[3] *= 0.6
      if @size <= 0.1
        clearInterval @loop
        callback.call()

    @loop = setInterval shrink, 40







  # do things a naub is supposed to do
  join_with: (other) ->
    join = Naubino.graph.add_join this, other
    @joins[join] = other
    @drawing_join[join] = true
    other.joins[join] = this
    other.drawing_join[join] = false
    Naubino.naub_joined.dispatch()
    join


  # the 'other' naub takes my place 
  replace_with: (other) ->
    remove_joins = for id, naub of @joins
      other.join_with(naub)
      delete naub.joins[id]
      Naubino.graph.remove_join id
    @layer.unfocus()
    @remove()
    console.log "replaced #{@number} with #{other.number}"
    Naubino.naub_replaced.dispatch(other.number)
    return 42


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

      diff = opos.Copy()
      diff.Subtract(pos)
      l = diff.Length()
    else
      NaN








  # user interaction
  focus: ->
    @focused = true
    @update()
    #@physics.friction = 10
    Naubino.naub_focused.dispatch(@)

  unfocus: ->
    @focused = false
    @update()
    #@physics.friction = @physics.default_friction
    Naubino.naub_unfocused.dispatch(@)

  isHit: (x, y) ->
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
