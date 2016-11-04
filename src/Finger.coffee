define ["Shapes"], (Shapes) ->\
class Finger

  constructor: (x,y,@id) ->

    @pos = cp.v(x,y)

    @friction   = Naubino.settings.naub.friction
    @elasticity = Naubino.settings.naub.elasticity
    @mass = 9001 #Naubino.settings.naub.mass
    @radius = 50

    #this part will be adjusted by shape
    @momentum = cp.momentForCircle( @mass, @radius, @radius, cp.vzero)
    @physical_body = new cp.Body( @mass, @momentum )
    @physical_body.name = "finger_#{@id}"
    @physical_body.setAngle( 0 ) # remember to set position
    @physical_body.p = @pos

    @physical_shape = new cp.CircleShape( @physical_body, @radius , cp.vzero )
    @physical_shape.setElasticity(@elasticity)
    @physical_shape.setFriction(@friction)

  draw_joins: ->

  draw: (ctx, x = 42, y = x) ->
    

  attracted_to: (_) ->

  is_alone: ->
    true


