# controlls everything that has to do with logic and gameplay or menus
# @extends Layer
define ["Physical_Layer", "Naub", "Graph", "CollisionHandler","Factory", "Finger"], (Physical_Layer, Naub, Graph, CollisionHandler, Factory, Finger) ->\

class Game extends Physical_Layer

  # get this started
  constructor: (canvas) ->
    @version = 0
    super(canvas)
    @name = "game"
    @graph = new Graph(this)
    @factory = new Factory this
    @begin_time = Date.now()

    # display stuff
    @focused_naub = null # points to the naub you click on

    #@points = -1
    @joining_allowed = yes
    #console.log "mousemove"
    #Naubino.mousemove.add @move_pointer
    #Naubino.mousedown.add @click
    #Naubino.mouseup.add @unfocus
    Naubino.touchmove.add @touchmove
    Naubino.touchstart.add @touchstart
    Naubino.touchend.add @touchend

    @joining_naubs = []
    @replacing_naubs = []
    @active_tree = []

    @setup_fsm Naubino.settings.events.game



  oninit: (e,f,t) ->
    console.log "game INIT"
    # gameplay
    @game_draw       = new Naubino.Signal()
    @naub_replaced   = new Naubino.Signal()
    @naub_joined     = new Naubino.Signal()
    @naub_destroyed  = new Naubino.Signal()
    @cycle_found     = new Naubino.Signal()
    @naub_focused    = new Naubino.Signal()
    @naub_unfocused  = new Naubino.Signal()

    #chipmunk
    @setup_physics()
    @space.defaultHandler = new CollisionHandler this




  onstopped: (e,f,t) -> @clear_objects() unless e is 'init'

  onloose: ->
    Naubino.loose('Naub Overflow') if Naubino.can 'loose'
    Naubino.background.pause()
    @stop_stepping()

    # after this point you must be able to press play an start again


  select_naub: (naub) =>
    if naub and naub.isClickable
      naub.focus() # TODO only one focus
      @focused_naub = naub # TODO focused_naubs <- naub

      @mouseBody.p = @pointer
      @mouseJoint = new cp.PivotJoint(@mouseBody, naub.physical_body, cp.vzero, cp.vzero)
      @mouseJoint.errorBias = Math.pow(1 - 0.5, 60)
      @space.addConstraint(@mouseJoint)

  touchstart: (x,y, id) =>
    return unless @space?

    naub = @get_obj_in_pos(cp.v(x,y))
    if naub
      # attach fingerbody
      @mousedown = true
      @pointer = new cp.v(x,y)
      @select_naub(naub)
    else
      # shove it around
      @create_finger_body(x,y,id)

  create_finger_body: (x,y,id) =>
    finger = new Finger(x,y,id)
    @fingersCollide[id] = finger
    @add_body_and_shape(finger) #todo remember the mouse body




  touchmove: (x,y, id) =>
    @move_pointer(x,y)
    finger = @fingersCollide[id]
    if finger?
      finger.pos.x = x
      finger.pos.y = y


  touchend: (x,y, id) =>
    @unfocus()
    finger = @fingersCollide[id]
    if finger?
      delete @fingersCollide[id]
      @remove_body_and_shape finger


  # callback for mouseup signal
  unfocus: =>
    if @mousedown
      @mousedown = false

      if @focused_naub
        @focused_naub.unfocus()

      @focused_naub = null
      if @space? && @mouseJoint?
        @space.removeConstraint @mouseJoint
        @mouseJoint = null

      @active_tree = []


  # counts how many naubs would be inside the circle
  # important for gameplay
  count_basket: (margin) ->
    count = []
    b_s = @basket_size()
    for id, naub of @objects
      diff = @center()
      diff.sub naub.physical_body.p
      if cp.v.len(diff) < b_s*(1+margin) - naub.size/2
        count.push naub
    count

  point_in_field: (pos) ->
    0 < pos.x < @width and 0 < pos.y < @height

  #calculates the size of the basket
  basket_size: ->
    if @max_naubs?
      n_r = Naubino.settings.naub.size / 2
      special_factor = .62 # discovered with scientific methods, don't ask
      b_r = Math.sqrt(@max_naubs * n_r * n_r / special_factor)

  # number of naubs currently in the basket
  cur_naubs: -> @count_basket(0.08).length

  # current space in basket in %
  # mainly here for compatibility reasons
  capacity: -> 100 - @cur_naubs() * 100 / @max_naubs

#   #shows how much room other.s available in the basket
#   capacity: ->
#     r = @basket_size
#     size= Math.ceil r * r * Math.PI * 0.68 # don't ask me why
#     filling =0
#     for naub in @count_basket()
#       filling += naub.area()
#     100-Math.ceil(filling*100 / size)

  # destroys every naub in a list of IDs by calling its own destroy function
  destroy_naubs: (list)->
    for naub in list
      @get_object(naub).disable()

    i = 0
    one_after_another= =>
      if i < list.length
        @get_object(list[i]).destroy(i == list.length-1)
        i++
      setTimeout one_after_another, 120
    one_after_another()


  # is one naub allowed to join with another
  check_joining: (a, b, arbiter) ->
    return no unless @joining_allowed
    return no unless a.focused or b.focused
    return no if a.disabled or b.disabled
    return no if a.number is b.number
    return no if arbiter.totalImpulse().Length() < Naubino.settings.game.min_joining_force

    # assigning better names the a and b
    naub  = if a.focused then a else b
    other = unless a.focused then a else b


    to_close = naub.close_related other # prohibits folding of pairs
    joined   = naub.is_joined_with other # can't join what's already joined
    agree    = naub.agrees_with(other) and other.agrees_with(naub)
    alone    = naub.is_alone() or other.is_alone()

    if not joined && agree && not to_close && not alone
      #console.info 'replace'
      #other.replace_with naub # chipmunk does not like me deleting objects inside a step
      @replacing_naubs.push [naub, other]
      return yes

    else if naub.is_alone() and naub.number isnt @just_joined
      #console.info 'join'
      #naub.join_with other
      @just_joined = naub.number
      setTimeout (=> @just_joined = -1), 300
      @joining_naubs.push [naub, other]
      return yes
    no

  # draws everything that happens inside the field
  draw:  ->
    # clears the canvas before drawing
    @clear()
    # draws joins and naubs seperately
    @ctx.save()

    @draw_constraints()
    @draw_fingers()
    @draw_point @pointer
    @draw_point @mouseBody.p, "blue"

    for id, obj of @objects
      obj.draw_joins @ctx
      obj.draw @ctx

    @ctx.restore()
    @game_draw.dispatch()



  draw_fingers: ->
    for _, finger of @fingersAttach
      @draw_point finger.pos, "green", finger.radius

    for _, finger of @fingersCollide
      @draw_point finger.pos, "green", finger.radius

  draw_constraints: ->
    for con, id in @space.constraints
      p1 = con.a.p
      p1 = con.anchr1 if p1.IsZero()
      p2 = con.b.p
      p2 = con.anchr2 if p2.IsZero()

      con_color = (con) ->
        switch con.name
          when "DampedSpring" then "red"
          when "SlideJoint"   then "blue"
          else "grey"

      if p1? and p2?
        @ctx.save()
        @ctx.strokeStyle = con_color con
        @ctx.moveTo p1.x, p1.y
        @ctx.lineTo p2.x, p2.y
        @ctx.stroke()
        @ctx.restore()
      if id?
        diff = p2.Copy()
        diff.sub(p1)
        join_string = id.toString()
        mid = cp.v.lerp(p1, p2, 0.5)
        @ctx.save()
        @ctx.translate mid.x,mid.y
        @ctx.rotate diff.Angle()
        @ctx.translate 0,-10
        @ctx.rotate 2*Math.PI - diff.Angle()
        @ctx.fillStyle = 'black'
        if con.a.isRogue() or con.b.isRogue()
          @ctx.fillStyle = 'red'
        @ctx.textAlign = 'center'
        @ctx.font= "10px Courier"
        @ctx.fillText(join_string, 0, 6)
        @ctx.restore()




  add_object:(obj) ->
    super obj
    obj.physical_body.naub_number = @objects_count if obj.physical_body?
    obj.physical_shape.naub_number = @objects_count if obj.physical_shape?
    obj.attracted_to @center()


  # clears the graph as well, just in case
  clear_objects: ->
    super()
    @setup_physics()
    @graph.clear()

  # run naub_forces, check for joinings and clean up
  step: (dt) ->
    @step_space()

    for pair in @replacing_naubs
      pair[0].replace_with pair[1]
      #console.log "replacing #{pair[0].number} with #{pair[1].number}"

    for pair in @joining_naubs
      pair[0].join_with pair[1]
      #console.log "joinging #{pair[0].number} with #{pair[1].number}"

    @joining_naubs = []
    @replacing_naubs = []

    # delete objects
    for id, obj of @objects
      if obj.removed
        @remove_obj id
        @clean_up()

  clean_up: ->
    #console.log "clean up run"
    for con, id in @space.constraints
      if con? and con.IsRogue()
        @space.removeConstraint con

