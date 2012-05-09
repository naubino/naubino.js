# controlls everything that has to do with logic and gameplay or menus
# @extends Layer
define ["Layer", "Naub", "Graph", "Shapes", "CollisionHandler"], (Layer, Naub, Graph, { Ball, Box, Frame, FrameCircle, Clock, NumberShape, StringShape, PlayButton, PauseButton }, CollisionHandler) -> class Game extends Layer

  # get this started
  constructor: (canvas) ->
    super(canvas)
    @name = "game"
    @graph = new Graph(this)
    @animation.name = "game.animation"

    # display stuff
    @focused_naub = null # points to the naub you click on

    #@points = -1
    @joining_allowed = yes
    console.log "mousemove"
    Naubino.mousemove.add @move_pointer
    Naubino.mousedown.add @click
    Naubino.mouseup.add @unfocus

    @centerjoins = []
    @joining_naubs = []
    @replacing_naubs = []
    
    # gameplay
    @naub_replaced   = new Naubino.Signal()
    @naub_joined     = new Naubino.Signal()
    @naub_destroyed  = new Naubino.Signal()
    @cycle_found     = new Naubino.Signal()
    @naub_focused    = new Naubino.Signal()
    @naub_unfocused  = new Naubino.Signal()

    #state machine
    StateMachine.create {
      target: this
      #error:(event,from,to,args,ec,em) -> console.warn "#{event}(#{args}): #{from}->#{to} - #{ec}:\"#{em}\"" unless event is 'click'
      events: Naubino.settings.events
    }


  oninit: ->
    #chipmunk
    @setup_physics()
    @space.defaultHandler = new CollisionHandler this


  #default state change actions
  onplaying: ->
    @animation.play()
    @start_stepper()

  onleaveplaying: (e,f,t) -> @stop_stepper()
  onpaused: (e,f,t) -> @animation.pause()
  onstopped: (e,f,t) ->



  add_object:(obj) ->
    super obj

    # attach it to its center
    if @space?
      #restLength, stiffness, damping
      rstl = Naubino.settings.physics.center_join.restLength
      stfs =  Naubino.settings.physics.center_join.stiffness
      dmpg =  Naubino.settings.physics.center_join.damping

      joint =
        new cp.DampedSpring( obj.physical_body, @space.staticBody, cp.vzero, obj.center, rstl, stfs, dmpg)
      @centerjoins.push joint
      @space.addConstraint( joint)
      obj.constraints.push joint

  
  # the game gives it the game takes it
  # FACTORIES

  #create n sets of matching pairs and some leftovers
  #
  # @param n [int] number of matching pairs
  # @param extras [int] number of leftovers
  create_matching_naubs: (n=1,extras=0) ->
    for [1..n]
      colors = Util.shuffle [0..5]
      colors[5] = colors[0]
      i = 0
      while i < (colors.length )-1
        pos  = @random_outside()
        #Naubino.background.draw_marker(x,y)
        [a,b] = @create_naub_pair(pos, colors[i],colors[i+1], off)
        #console.log "pairing " + [a,b]
        i++

    #create some extras
    if extras > 0
      for [1..extras]
        pos  = @random_outside()
        #Naubino.background.draw_marker(x,y)
        @create_naub_pair(pos)

  # factory for a naub ball
  # 
  # @param pos [cp.v] position
  # @param color [int]  color_id
  add_ball: (pos = @random_outside(), color = null) =>
    naub = new Naub this, color
    ball = new Ball

    naub.add_shape ball
    naub.setup_physics()
    naub.physical_body.setPos( pos.Copy() ) # remember to set position
    naub.kind = 'ball'

    @add_object naub
    #naub.add_shape new NumberShape
    #naub.update() # again just to get the numbers
    naub


  # factory for a naub box
  # 
  # @param pos [cp.v] position
  # @param color [int]  color_id
  add_box: (pos = @random_outside(), color = null) =>
    naub = new Naub this, color
    box = new Box

    naub.add_shape box
    naub.setup_physics()
    # turn a circle into a box
    box.adjust_physics()

    naub.physical_body.setPos( pos.Copy() ) # remember to set position
    naub.kind = 'box'

    @add_object naub
    #naub.add_shape new NumberShape
    #naub.update() # again just to get the numbers
    naub

  #returns a random 
  random_factory: ->
    factories = [
      @add_ball
      @add_box
    ]
    console.log 'i', i = Math.floor(Math.random() * (factories.length))
    factories[i]

  # create a pair of joined naubs
  #
  # @default
  # @param x [int] x-ordinate
  # @param y [int] y-ordinate
  # @param color [int] color id of naub 1
  # @param color [int] color id of naub 2
  # IMPLICIT if game has a @max_colors int random colors will only be picked out range [1..@max_colors]
  create_naub_pair: (pos = null, color_a = null, color_b = null, mixed = off) =>
    pos = @random_outside() unless pos?
    dir = Math.random() * Math.PI
    pos_a = pos.Copy()
    pos_b = pos.Copy()

    #TODO auskommentiert
    #pos_a.AddPolar(dir,  15)
    #pos_b.AddPolar(dir, -15)

    if mixed
      factory1 = @random_factory()
      factory2 = @random_factory()
    else
      factory1 = factory2 = @add_ball

    naub_a = factory1 pos_a, color_a
    naub_b = factory2 pos_b, color_b

    naub_a.join_with naub_b
    [naub_a.color_id, naub_b.color_id]

  # create a triple of joined naubs
  #
  # works almost like create_naub_pair
  # @param x [int] x-ordinate
  # @param y [int] y-ordinate
  create_naub_triple: (pos = null, color_a = null, color_b = null, color_c = null) =>
    pos = @random_outside() unless pos?
    dir = Math.random() * Math.PI
    pos_a = pos.Copy()
    pos_b = pos.Copy()
    pos_c = pos.Copy()

    # TODO auskommentiert
    #pos_a.AddPolar(dir,  30)
    #pos_c.AddPolar(dir, -30)

    naub_a = @add_ball pos_a, color_a
    naub_b = @add_ball pos_b, color_b
    naub_c = @add_ball pos_c, color_c

    naub_a.join_with naub_b
    naub_b.join_with naub_c










  # callback for mousedown signal
  click: (x, y) =>
    @mousedown = true
    @pointer = new cp.v x,y

    shape = @space.pointQueryFirst(@pointer, @GRABABLE_MASK_BIT, cp.NO_GROUP) if @space?
    naub = @get_object shape.naub_number if shape?
    if naub
      naub.focus()
      @focused_naub = naub

      @mouseBody.p = @pointer
      @mouseJoint = new cp.PivotJoint(@mouseBody, naub.physical_body, cp.v(0,0), cp.v(0,0))
      @mouseJoint.maxForce = 50000
      @mouseJoint.errorBias = Math.pow(1 - 0.15, 60)
      @space.addConstraint(@mouseJoint)

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



  # produces a random set of coordinates outside the field
  random_outside: ->
    offset = Naubino.settings.game.creation_offset
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
    new cp.v x,y

  # counts howmany naubs would be inside the circle
  # important for gameplay
  count_basket: ->
    count = []
    if @basket_size?
      for id, naub of @objects
        diff = new cp.v @center.x, @center.y
        diff.sub naub.physical_body.p
        if cp.v.len(diff) < @basket_size - naub.size/2
          count.push naub
    count


  # shows how much room is available in the basket
  capacity: ->
    r = @basket_size
    size= Math.ceil r * r * Math.PI * 0.68 # don't ask me why
    filling =0
    for naub in @count_basket()
      filling += naub.area()
    100-Math.ceil(filling*100 / size)

  # destroys every naub in a list of IDs by calling its own destroy function
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


  # is one naub allowed to join with another
  check_joining: (naub, other, arbiter) ->
    return no if naub.number == other.number or not @joining_allowed
    return no unless naub.focused or other.focused

    force = arbiter.totalImpulse().Length()
    return no if force < Naubino.settings.game.min_joining_force
    console.log force


    close_related = naub.close_related other # prohibits folding of pairs
    joined = naub.is_joined_with other # can't join what's already joined

    agrees = naub.agrees_with(other) and other.agrees_with(naub)

    if !naub.disabled && not joined && agrees && not close_related && not naub.alone() && not other.alone()
      console.info 'replace'
      #other.replace_with naub # chipmunk does not like me deleting objects inside a step
      @replacing_naubs.push [naub, other]
      return yes
    else if naub.alone() and not (other.disabled or naub.disabled)
      console.info 'join'
      #naub.join_with other
      @joining_naubs.push [naub, other]
      return yes
    no

  # draws everything that happens inside the field
  draw:  ->
    # clears the canvas before drawing
    @ctx.clearRect(0, 0, Naubino.settings.canvas.width, Naubino.settings.canvas.height)
    # draws joins and naubs seperately
    @ctx.save()
    for id, obj of @objects
      obj.draw_joins @ctx

    for id, obj of @objects
      obj.draw @ctx

    @draw_point @pointer
    @draw_point @mouseBody.p, "red"
    @ctx.restore()



  # clears the graph as well, just in case
  clear_objects: ->
    @for_each (o)-> o.remove()
    @graph.clear()

  # run naub_forces, check for joinings and clean up
  step: (dt) ->
    super()
    
    #@naub_forces dt

    for pair in @replacing_naubs
      pair[0].replace_with pair[1]
      console.log "replacing #{pair[0].number} with #{pair[1].number}"

    for pair in @joining_naubs
      pair[0].join_with pair[1]
      console.log "joinging #{pair[0].number} with #{pair[1].number}"

    @joining_naubs = []
    @replacing_naubs = []

    # delete objects
    for id, obj of @objects
      if obj.removed
        @remove_obj id
        return 42 # TODO found out if there is a way to have a void function?




  # moves naubs on every step
  #
  # @param [float] time-difference determines step size
  naub_forces: (dt) ->
    for id, naub of @objects

      # everything moves toward the middle
      naub.physics.gravitate(dt)

      # joined naubs have spring forces
      for id, other of naub.joins
        naub.physics.join_springs other

      # collide
      for [0..3]
        for id, other of @objects
          naub.physics.collide other

      # use all previously calculated forces and actually move the damn thing
      naub.step(dt)

