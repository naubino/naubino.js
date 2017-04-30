define ["Shapes"], (Shapes) ->\
class Finger

  constructor: (@id,x,y) ->
    @pointer = cp.v x,y # indirection for smoother dragging

  @create_colliding: (space, x,y, id) ->
    new Finger(id,x,y).colliding(space)

  colliding: (space) ->
    @kind = "colliding"

    @friction   = Naubino.settings.naub.friction
    @elasticity = 0
    @mass = 9001 #Naubino.settings.naub.mass
    @radius = 25

    #this part will be adjusted by shape
    @momentum = cp.momentForCircle( @mass, @radius, @radius, cp.vzero)
    @body = new cp.Body( @mass, @momentum )
    @body.name = "finger_#{@id}"
    @body.setAngle( 0 ) # remember to set position
    @body.p = cp.v(@pointer.x, @pointer.y)
    space.addBody(@body)

    @shape = new cp.CircleShape( @body, @radius , cp.vzero )
    @shape.setElasticity(@elasticity)
    @shape.setFriction(@friction)
    space.addShape(@shape)
    this

  remove: () ->
    @removed = true

  rly_remove: (space) ->
    console.info "rly remove"
    switch @kind
      when "colliding"
        space.removeBody(@body)
        space.removeShape(@shape)
      when "attached"
        space.removeConstraint(@joint)
        space.removeBody(@body)

  @create_attached: (space, naub, x,y, id) ->
    new Finger(id,x,y).attach(space, naub)

  attach: (space, naub) ->
    @kind = "attached"
    @body = new cp.Body(Infinity, Infinity)
    @body.name = "finger_#{@id}"
    @body.p = cp.v(@pointer.x, @pointer.y)
    space.addBody(@body)
    @joint = new cp.PivotJoint(@body, naub.physical_body, cp.vzero, cp.vzero)
    @joint.errorBias = Math.pow(1 - 0.5, 60)
    space.addConstraint(@joint)
    this

  step: ->
    newPoint = cp.v.lerp(@body.p, @pointer, 0.25)
    @body.v = cp.v.mult(cp.v.sub(newPoint, @body.p), 60)
    @body.p = newPoint

