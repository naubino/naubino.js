import {PhysicsWorld} from './PhysicsWorld'

# the mode agnostic part: object registry, physics, naub lifecycle signals
# no canvas, no graph
export class World
  constructor: (width, height, physics_config = Naubino.settings.physics, @events) ->
    @physics_config = physics_config
    @center = new cp.v width / 2, height / 2
    @objects       = {}
    @objects_count = 0
    @joins = {}
    @join_id_sequence = 0
    @reset_physics width, height, @physics_config

  reset_physics: (width, height, physics_config = @physics_config) ->
    @physics = new PhysicsWorld(width, height, physics_config)


  add_object: (obj) ->
    @physics.add_object obj
    ++@objects_count
    obj.number = @objects_count
    @objects[@objects_count] = obj
    obj.events = @events
    obj.center = @center.Copy()
    obj.physical_body.naub_number = obj.number if obj.physical_body?
    obj.physical_shape.naub_number = obj.number if obj.physical_shape?
    if obj.physical_body?
      obj.centerjoin = @physics.attract_to_center obj.physical_body, obj.center
      obj.constraints.center = obj.centerjoin
    @objects_count

  get_object: (id) -> @objects[id]

  naubs: -> Object.values @objects

  join: (first, second, silent = false) ->
    return -1 unless first? and second? and first isnt second
    return -1 unless @get_object(first.number) is first and @get_object(second.number) is second
    return -1 if first.removed or second.removed or first.is_joined_with second

    minlen = Naubino.settings.naub.min_join_len * first.size
    maxlen = Naubino.settings.naub.max_join_len * first.size
    constraints = @physics.join_bodies first.physical_body, second.physical_body, minlen, maxlen
    id = ++@join_id_sequence
    @joins[id] = {first, second, constraints}
    first.joins[id] = second
    second.joins[id] = first
    first.drawing_join[id] = true
    second.drawing_join[id] = false
    @events?.join_added.dispatch id, first.number, second.number
    @events?.naub_joined.dispatch first.number unless silent
    id

  split: (id) ->
    join = @joins[id]
    return unless join?
    {first, second, constraints} = join
    @physics.unjoin constraints
    delete first.joins[id]
    delete second.joins[id]
    delete first.drawing_join[id]
    delete second.drawing_join[id]
    delete @joins[id]
    @events?.join_removed.dispatch Number(id)
    return

  replace: (kept, removed) ->
    return unless kept? and removed? and kept isnt removed
    return unless @get_object(kept.number) is kept and @get_object(removed.number) is removed
    return if kept.removed or removed.removed
    for id in Object.keys removed.joins
      partner = removed.joins[id]
      @join kept, partner
      @split id
    kept.physical_body.p = cp.v.lerp kept.physical_body.p, removed.physical_body.p, 0.5
    removed.remove()
    @events?.naub_replaced.dispatch kept.number
    return

  remove_object: (id) ->
    naub = @get_object id
    return unless naub?
    @split join_id for join_id in Object.keys naub.joins
    if naub.centerjoin?
      @physics.unjoin [naub.centerjoin]
      delete naub.centerjoin
      delete naub.constraints.center
    @physics.remove_object naub
    naub.removed = true
    delete @objects[id]
    return

  # objects_count keeps going on purpose, see constructor
  clear: (width, height) ->
    @remove_object id for id in Object.keys @objects
    @objects = {}
    @reset_physics width, height, @physics_config

  # clickable naubs only
  naub_at: (pos) ->
    shape = @physics.space.pointQueryFirst(pos, @physics.GRABABLE_MASK_BIT, cp.NO_GROUP)
    naub = @get_object shape.naub_number if shape?
    naub if naub? and naub.isClickable
