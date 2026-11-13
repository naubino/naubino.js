import {PhysicsWorld} from './PhysicsWorld'

# the mode agnostic part: object registry, physics, naub lifecycle signals
# no canvas, no graph
export class World
  constructor: (width, height, physics_config = Naubino.settings.physics) ->
    @physics_config = physics_config
    @objects       = {}
    @objects_count = 0
    @reset_physics width, height, @physics_config

  reset_physics: (width, height, physics_config = @physics_config) ->
    @physics = new PhysicsWorld(width, height, physics_config)


  add_object: (obj) ->
    @physics.add_object obj
    ++@objects_count
    obj.number = @objects_count
    @objects[@objects_count] = obj
    @objects_count

  get_object: (id) -> @objects[id]

  remove_object: (id) ->
    @physics.remove_object @objects[id]
    delete @objects[id]

  # objects_count keeps going on purpose, see constructor
  clear: (width, height) ->
    @objects = {}
    @reset_physics width, height, @physics_config

  # clickable naubs only
  naub_at: (pos) ->
    shape = @physics.space.pointQueryFirst(pos, @physics.GRABABLE_MASK_BIT, cp.NO_GROUP)
    naub = @get_object shape.naub_number if shape?
    naub if naub? and naub.isClickable
