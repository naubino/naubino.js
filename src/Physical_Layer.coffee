import {Layer} from './Layer'
import {PhysicsWorld} from './PhysicsWorld'

export class Physical_Layer extends Layer

  setup_physics: ->
    @physics = new PhysicsWorld(@width, @height)
    # kept directly on the layer: Game and Naub reach into these
    @space             = @physics.space
    @mouseBody         = @physics.mouseBody
    @GRABABLE_MASK_BIT = @physics.GRABABLE_MASK_BIT
    @NOT_GRABABLE_MASK = @physics.NOT_GRABABLE_MASK

  add_walls: ->
    @physics.add_walls()
    @walls = @physics.walls


  step_space: (dt) ->
    @physics.step(dt, @pointer)


  add_object: (obj)->
    #chipmunk
    @physics.add_object(obj) if @space?
    super(obj)


  # asks all objects whether they have been hit by pointer
  get_obj_in_pos: (pos) ->
    if @space?
      shape = @space.pointQueryFirst(pos, @GRABABLE_MASK_BIT, cp.NO_GROUP)
      naub = @get_object shape.naub_number if shape?
      if naub? and naub.isClickable
        return naub
    else
      super(pos)


  remove_obj: (id) ->
    obj = @get_object id
    @physics.remove_object(obj) if @space?
    delete @objects[id]
