define ["Layer"], (Layer) ->\

class Physical_Layer extends Layer

  setup_physics: ->
    @GRABABLE_MASK_BIT = 1<<31
    @NOT_GRABABLE_MASK = ~@GRABABLE_MASK_BIT
    @space = new cp.Space() # so far so good
    @space.damping = Naubino.settings.physics.damping
    @mouseBody = new cp.Body(Infinity, Infinity)
    @mouseBody.name = "mouseBody"
    @mouseBody.p = cp.vzero
    @space.addBody @mouseBody

  add_walls: ->
    ws = 15 #wall_strength
    @walls = {}
    walls=
      ceil  : new cp.SegmentShape(@space.staticBody, cp.vzero, cp.v(@width, 0), ws)
      floor : new cp.SegmentShape(@space.staticBody, cp.v(0,@height), cp.v(@width, @height), ws)
      left  : new cp.SegmentShape(@space.staticBody, cp.vzero, cp.v(0,@height), ws)
      right : new cp.SegmentShape(@space.staticBody, cp.v(@width, 0), cp.v(@width ,@height), ws)

    for w, wall of walls
      @walls[w] = @space.addShape(wall)
      @walls[w].setElasticity(.01)
      @walls[w].setFriction(3)
      @walls[w].setLayers(@NOT_GRABABLE_MASK)
      @walls[w].group = 1



  step_space: ->
    @space.step(1/@step_rate)
    # Move mouse body toward the mouse
    newPoint = cp.v.lerp(@mouseBody.p, @pointer, 0.25)
    @mouseBody.v = cp.v.mult(cp.v.sub(newPoint, @mouseBody.p), 60)
    @mouseBody.p = newPoint


  add_object: (obj)->
    #chipmunk
    if @space?
      @space.addShape obj.physical_shape if obj.physical_shape?
      @space.addBody obj.physical_body if obj.physical_body?
    super(obj)


  # asks all objects whether they have been hit by pointer
  get_obj_in_pos: (pos) ->
    if @space?
      shape = @space.pointQueryFirst(@pointer, @GRABABLE_MASK_BIT, cp.NO_GROUP) if @space?
      naub = @get_object shape.naub_number if shape?
      if naub.isClickable
        return naub
    else
      super(pos)


  remove_obj: (id) ->
    obj = @get_object id
    if @space?
      @space.removeShape obj.physical_shape if obj.physical_shape?
      @space.removeBody obj.physical_body if obj.physical_body?
      for constraint in obj.constraints
        #console.log constraint
        @space.removeConstraint constraint
    delete @objects[id]


