# controlls everything that has to do with logic and gameplay or menus
# @extends Layer
define ["Layer", "Naub", "Graph", "CollisionHandler","Factory"], (Layer, Naub, Graph, CollisionHandler, Factory) -> class Game extends Layer

  # get this started
  constructor: (canvas) ->
    super(canvas)
    @name = "game"
    @graph = new Graph(this)
    @animation.name = "game.animation"
    @factory = new Factory this

    # display stuff
    @focused_naub = null # points to the naub you click on

    #@points = -1
    @joining_allowed = yes
    console.log "mousemove"
    Naubino.mousemove.add @move_pointer
    Naubino.mousedown.add @click
    Naubino.mouseup.add @unfocus

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

    obj.physical_body.naub_number = @objects_count if obj.physical_body?
    obj.physical_shape.naub_number = @objects_count if obj.physical_shape?
    obj.attach_to @center
  




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
      @mouseJoint = new cp.PivotJoint(@mouseBody, naub.physical_body, cp.vzero, cp.vzero)
      @mouseJoint.errorBias = Math.pow(1 - 0.5, 60)
      @space.addConstraint(@mouseJoint)
      
      # make naubs lighter
      #attached_naubs = @graph.tree(naub.number)
      #for n in attached_naubs
      #  naub = @get_object n
      #  #naub.physical_shape.setFriction Naubino.settings.naub.sticky



  # callback for mouseup signal
  unfocus: =>
    if @mousedown
      @mousedown = false

      if @focused_naub
        # undo make naubs lighter
        #attached_naubs = @graph.tree(@focused_naub.number)
        #for n in attached_naubs
        #  naub = @get_object n
        #  #naub.physical_shape.setFriction Naubino.settings.naub.slick

        @focused_naub.unfocus()
      @focused_naub = null
      if @space? && @mouseJoint?
        @space.removeConstraint @mouseJoint
        @mouseJoint = null


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

  point_in_field: (pos) ->
    0 < pos.x < @width and 0 < pos.y < @height

  # shows how much room other.s available in the basket
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
    @draw_point @mouseBody.p, "blue"
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




