class World
  constructor: (@field) ->
    @center = new b2Vec2 @field[2]/2, @field[2]/2
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
    for naub in @objs
      { pos, vel, force } = naub.physics
      
      # move to center
      v = @center.Copy()
      v.Subtract(pos)
      v.Normalize()
      v.Multiply(4000)
      force.Add(v)
      
      # collide
      for other in @objs
        { pos: opos, vel: ovel, force: oforce } = other.physics
        diff = opos.Copy()
        diff.Subtract(pos)
        l = diff.Length()
        if l < 30
          diff.Normalize()
          v = diff.Copy()
          v.Multiply(4000)
          force.Subtract(v)
          oforce.Add(v)
    
  add_obj: (obj) ->
    @objs.push obj
    
  remove_obj: (obj) ->
    @objs.splice(@objs.indexOf(obj),1)
