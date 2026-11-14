export class PhysicsWorld
  constructor: (@width, @height, @config = Naubino.settings.physics) ->
    @GRABABLE_MASK_BIT = 1<<31
    @NOT_GRABABLE_MASK = ~@GRABABLE_MASK_BIT
    @space = new cp.Space()
    @space.damping = @config.damping
    @mouseBody = new cp.Body(Infinity, Infinity)
    @mouseBody.name = "mouseBody"
    @mouseBody.p = cp.vzero
    @space.addBody @mouseBody

  resize: (@width, @height) ->
    if @walls?
      @space.removeShape wall for name, wall of @walls
      @add_walls()
    return

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

  step: (dt, pointer) ->
    @space.step(dt)
    newPoint = cp.v.lerp(@mouseBody.p, pointer, 0.25)
    @mouseBody.v = cp.v.mult(cp.v.sub(newPoint, @mouseBody.p), 60)
    @mouseBody.p = newPoint

  add_object: (obj) ->
    @space.addShape obj.physical_shape if obj.physical_shape?
    @space.addBody obj.physical_body if obj.physical_body?

  remove_object: (obj) ->
    @space.removeShape obj.physical_shape if obj.physical_shape?
    @space.removeBody obj.physical_body if obj.physical_body?
    for constraint in obj.constraints
      @space.removeConstraint constraint

  # returns both, otherwise unjoin leaves the spring behind
  join_bodies: (body_a, body_b, minlen, maxlen) ->
    spring = new cp.DampedSpring( body_a, body_b, cp.vzero, cp.vzero, minlen, 10, 30)
    spring.name = "DampedSpring"
    @space.addConstraint(spring)

    slide = new cp.SlideJoint( body_a, body_b, cp.vzero, cp.vzero, minlen, maxlen)
    slide.name = "SlideJoint"
    @space.addConstraint(slide)

    [spring, slide]

  # takes whatever join_bodies returned
  unjoin: (constraints) ->
    for con in constraints
      @space.removeConstraint con


  attract_to_center: (body, center) ->
    rstl = @config.center_join.restLength
    stfs = @config.center_join.stiffness
    dmpg = @config.center_join.damping
    spring = new cp.DampedSpring( body, @space.staticBody, cp.vzero, center, rstl, stfs, dmpg)
    spring.centerjoin = true
    @space.addConstraint(spring)
    spring
