define ["Shapes"], (Shapes) ->\
class Finger

  constructor: (@id,x,y) ->
    @pos = cp.v x,y

  @create_colliding: (space, x,y, id) ->
    new Finger(id,x,y).colliding(space)

  colliding: (space) ->
    @kind = "colliding"

    @friction   = Naubino.settings.naub.friction
    @elasticity = Naubino.settings.naub.elasticity
    @mass = 9001 #Naubino.settings.naub.mass
    @radius = 50

    #this part will be adjusted by shape
    @momentum = cp.momentForCircle( @mass, @radius, @radius, cp.vzero)
    @body = new cp.Body( @mass, @momentum )
    @body.name = "finger_#{@id}"
    @body.setAngle( 0 ) # remember to set position
    @body.p = @pos
    space.addBody(@body)

    @shape = new cp.CircleShape( @body, @radius , cp.vzero )
    @shape.setElasticity(@elasticity)
    @shape.setFriction(@friction)
    space.addShape(@shape)
    this

  remove: (space) ->
    switch @kind
      when "colliding"
        space.removeBody(@body)
        space.removeShape(@shape)
      when "attached"
        space.removeBody(@body)
        space.removeConstraint(@joint)

  @create_attached: (space, naub, x,y, id) ->
    new Finger(id,x,y).attach(space, naub)

  attach: (space, naub) ->
    @kind = "attached"
    @body = new cp.Body(Infinity, Infinity)
    @body.name = "finger_#{@id}"
    @body.p = @pos
    space.addBody(@body)
    @joint = new cp.PivotJoint(@body, naub.physical_body, cp.vzero, cp.vzero)
    @joint.errorBias = Math.pow(1 - 0.5, 60)
    space.addConstraint(@joint)
    this

  draw_joins: ->

  draw: (ctx, x = 42, y = x) ->
    

  attracted_to: (_) ->

  is_alone: ->
    true


