# controlls everything that has to do with logic and gameplay or menus
# @extends Layer
import {Layer} from "../core/Layer"
import {World} from "./World"
import {Naub} from "./Naub"
import {Graph} from "./Graph"
import {CollisionHandler} from "./CollisionHandler"
import {Factory} from "./Factory"
import {DragSystem} from "./DragSystem"
import {Mode} from "../modes/Mode"

export class Game extends Layer

  # get this started
  constructor: (canvas, @mode = new Mode, @events = Naubino.events) ->
    super(canvas)
    @config = @build_config()
    @world = new World(@width, @height, @config.physics)
    @expose_world()
    @version = @mode.version
    @mode_id = @mode.id
    @name = "game"
    @variable_timestep = yes
    @use_raf = yes
    @graph = new Graph(this)
    @factory = new Factory(this)
    @join_policy = @mode.join_policy this
    @drag = new DragSystem(this)
    @begin_time = Date.now()


    # display stuff
    @focused_naub = null # points to the naub you click on

    #@points = -1
    @joining_allowed = yes
    @input_unsubscribers = []
    @input_unsubscribers.push @events.input.pointer_move.add @move_pointer
    @input_unsubscribers.push @events.input.pointer_start.add @click
    @input_unsubscribers.push @events.input.pointer_end.add @unfocus

    @joining_naubs = []
    @replacing_naubs = []
    @active_tree = []

    @setup_fsm Naubino.settings.events.game

    # last, rules may want everything above
    @rules = @mode.rules this
    @mode_unsubscribe = @mode.bind this, @events


  build_config: ->
    game = Object.assign {}, Naubino.settings.game, @mode.game_config ? {}
    physics_overrides = @mode.physics_config ? {}
    physics = Object.assign {}, Naubino.settings.physics, physics_overrides
    physics.center_join = Object.assign {}, Naubino.settings.physics.center_join, physics_overrides.center_join ? {}
    {game, physics}

  # plenty of code still reads these off the game directly
  # rerun whenever the world swaps one out
  expose_world: ->
    @objects           = @world.objects
    @physics           = @world.physics
    @space             = @physics.space
    @mouseBody         = @physics.mouseBody
    @GRABABLE_MASK_BIT = @physics.GRABABLE_MASK_BIT
    @NOT_GRABABLE_MASK = @physics.NOT_GRABABLE_MASK
    @naub_joined       = @world.naub_joined
    @naub_destroyed    = @world.naub_destroyed
    @naub_focused      = @world.naub_focused
    @naub_unfocused    = @world.naub_unfocused

  oninit: (e,f,t) ->
    @cancel_destroy_batches()
    @mode.reset? this
    console.log "Game INIT from '#{f}'"
    # gameplay
    @game_draw       = new Naubino.Signal()
    @naub_replaced   = new Naubino.Signal()
    @cycle_found     = new Naubino.Signal()
    @world.reset_signals()
    @naub_joined    = @world.naub_joined
    @naub_destroyed = @world.naub_destroyed

    #chipmunk
    @setup_physics()
    @space.defaultHandler = new CollisionHandler this

    # audio
    Naubino.audio.connect_to_game this

    rule.init() for rule in @rules
    @mode.init this
    return

  onplaying: (e,f,t) ->
    @begin_time = Date.now() if f is 'stopped'
    @duration = 0 if f is 'stopped'
    rule.start() for rule in @rules
    @checking = setInterval @check, 300 unless @checking
    @mode.playing this, f
    return

  onleaveplaying: ->
    rule.stop() for rule in @rules
    @mode.stop? this
    clearInterval @checking
    @checking = null
    return

  # recurring check (@checking)
  check: =>
    rule.check() for rule in @rules
    return

  setup_physics: ->
    @world.reset_physics @width, @height, @config.physics
    @expose_world()

  resize: (@width, @height) ->
    # Springs must follow the field's new center.
    center = @center()
    @for_each (naub) ->
      naub.center = center.Copy()
      naub.constraints?.center?.anchr2 = center.Copy()

  score_snapshot: -> @mode.result this




  # Forced stops skip the mode's confirmation.
  onbeforestop: (e,f,t, force = no) ->
    return true if force
    @mode.confirm_stop()

  onstopped: (e,f,t) ->
    unless e is 'init'
      @cancel_destroy_batches()
      @clear_objects()

  onloose: (e, from, to, reason = 'Game Over') ->
    @stop_stepping()
    @events.game.outcome.dispatch reason

  dispose: ->
    rule.stop() for rule in @rules
    @mode.stop? this
    @mode_unsubscribe?()
    @mode_unsubscribe = null
    @mode.dispose? this
    @stop_stepping()
    @stop_drawing()
    @cancel_destroy_batches()
    clearInterval @checking if @checking?
    @checking = null
    unsubscribe() for unsubscribe in (@input_unsubscribers ? []) when typeof unsubscribe is 'function'
    @input_unsubscribers = []

    # after this point you must be able to press play an start again


  # callback for mousedown signal
  click: (x, y) =>
    @mousedown = true
    @pointer = new cp.v x,y
    @drag.start(@pointer)

  # callback for mouseup signal
  unfocus: =>
    if @mousedown
      @mousedown = false
      @drag.stop()



  point_in_field: (pos) ->
    0 < pos.x < @width and 0 < pos.y < @height

  cancel_destroy_batches: ->
    clearTimeout batch.timer for batch in (@destroy_batches ? []) when batch.timer?
    @destroy_batches = []
    @destroying_naubs = {}

  # destroys every naub in a list of IDs by calling its own destroy function
  destroy_naubs: (list) ->
    @destroy_batches ?= []
    @destroying_naubs ?= {}
    ids = []
    for id in list
      naub = @get_object id
      continue unless naub? and not naub.removed and not naub.destroying and not @destroying_naubs[id]
      naub.disable()
      @destroying_naubs[id] = yes
      ids.push id
    return unless ids.length

    batch = {ids, index: 0, timer: null}
    @destroy_batches.push batch
    destroy_next = =>
      return unless batch in @destroy_batches
      id = batch.ids[batch.index]
      naub = @get_object id
      if naub? and not naub.removed and not naub.destroying
        naub.destroy(batch.index == batch.ids.length - 1)
      else unless naub?
        delete @destroying_naubs[id]
      batch.index++
      if batch.index < batch.ids.length
        batch.timer = setTimeout destroy_next, 120
      else
        @destroy_batches.splice @destroy_batches.indexOf(batch), 1
    destroy_next()


  # is one naub allowed to join with another
  check_joining: (a, b, arbiter) ->
    @join_policy.check_joining(a, b, arbiter)

  # draws everything that happens inside the field
  draw:  ->
    # clears the canvas before drawing
    @clear()
    # draws joins and naubs seperately
    @ctx.save()

    if Naubino.settings.graphics.draw_constraints
      @draw_constraints()
    if Naubino.settings.graphics.draw_pointer
      @draw_point @pointer
      # @draw_point @mouseBody.p, "blue"

    for id, obj of @objects
      obj.draw_joins @ctx
      obj.draw @ctx

    @ctx.restore()
    @game_draw.dispatch()



  draw_constraints: ->
    for con, id in @space.constraints
      p1 = con.a.p
      p1 = con.anchr1 if p1.IsZero()
      p2 = con.b.p
      p2 = con.anchr2 if p2.IsZero()

      con_color = (con) ->
        switch con.name
          when "DampedSpring" then "red"
          when "SlideJoint"   then "blue"
          else "grey"

      if p1? and p2?
        @ctx.save()
        @ctx.strokeStyle = con_color con
        @ctx.moveTo p1.x, p1.y
        @ctx.lineTo p2.x, p2.y
        @ctx.stroke()
        @ctx.restore()
      if id?
        diff = p2.Copy()
        diff.sub(p1)
        join_string = id.toString()
        mid = cp.v.lerp(p1, p2, 0.5)
        @ctx.save()
        @ctx.translate mid.x,mid.y
        @ctx.rotate diff.Angle()
        @ctx.translate 0,-10
        @ctx.rotate 2*Math.PI - diff.Angle()
        @ctx.fillStyle = 'black'
        if con.a.isRogue() or con.b.isRogue()
          @ctx.fillStyle = 'red'
        @ctx.textAlign = 'center'
        @ctx.font= "10px Courier"
        @ctx.fillText(join_string, 0, 6)
        @ctx.restore()




  add_object:(obj) ->
    obj.center = @center()
    number = @world.add_object obj
    obj.physical_body.naub_number = number if obj.physical_body?
    obj.physical_shape.naub_number = number if obj.physical_shape?
    obj.attracted_to @center()

  get_object: (id) -> @world.get_object id

  remove_obj: (id) ->
    delete @destroying_naubs[id] if @destroying_naubs?
    @world.remove_object id

  get_obj_in_pos: (pos) -> @world.naub_at pos

  # clears the graph as well, just in case
  clear_objects: ->
    @world.clear @width, @height
    @expose_world()
    @graph.clear()

  # run naub_forces, check for joinings and clean up
  step: (dt) ->
    @physics.step(dt, @pointer)

    for pair in @replacing_naubs
      pair[0].replace_with pair[1]
      #console.log "replacing #{pair[0].number} with #{pair[1].number}"

    for pair in @joining_naubs
      pair[0].join_with pair[1]
      #console.log "joinging #{pair[0].number} with #{pair[1].number}"

    @joining_naubs = []
    @replacing_naubs = []

    # delete objects
    for id, obj of @objects
      if obj.removed
        @remove_obj id
        @clean_up()

  clean_up: ->
    #console.log "clean up run"
    for con, id in @space.constraints
      if con? and con.IsRogue()
        @space.removeConstraint con
