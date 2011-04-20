class World
  constructor: (@field) ->
    @objs = []
    
  draw: (ctx) ->
    for obj in @objs
      obj.draw ctx
      
  step: (dt) ->
    @naub_forces dt
    for obj in @objs
      obj.step dt
    for obj in @objs
      @world.remove_obj(this) if obj.removed
    
  naub_forces: (dt) ->
    center = new b2Vec2 300, 200
    for naub in @objs
      { pos, vel, force } = naub.physics
      v = center.Copy()
      v.Subtract(pos)
      v.Normalize()
      v.Multiply(4000)
      force.Add(v)
    
  add_obj: (obj) ->
    @objs.push obj
    
  remove_obj: (obj) ->
    @objs.splice(@objs.indexOf(obj),1)
