class World
  constructor: (@field) ->
    @objs = []
    
  draw: (ctx) ->
    for obj in @objs
      obj.draw ctx
      
  step: (dt) ->
    console.log 1
    for obj in @objs
      obj.step dt
    for obj in @objs
      @world.remove_obj(this) if obj.removed
    
  add_obj: (obj) ->
    @objs.push obj
    
  remove_obj: (obj) ->
    @objs.splice(@objs.indexOf(obj),1)
