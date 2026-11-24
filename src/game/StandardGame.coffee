import {Game} from './Game'
import {Spawner} from '../modes/standard/Spawner'
import {Scoring} from '../modes/standard/Scoring'
import {Overflow} from '../modes/standard/Overflow'
import {Levels} from '../modes/standard/Levels'
import {Basket} from '../modes/standard/Basket'

export class StandardGame extends Game
  constructor: (args...) ->
    super args...
    @basket = new Basket this
    @spawner = new Spawner this
    @scoring = new Scoring this
    @overflow = new Overflow this
    @levels = new Levels this, @spawner, @mode.level_details
    @rules = [@spawner, @scoring, @overflow, @levels]
    {signal} = @abort_controller
    @events.naub_replaced.add ((number) => @check_cycles number), signal
    @events.cycle_found.add ((list) => @destroy_naubs list), signal
    @events.naub_focused.add ((naub) => @active_tree = @graph.tree naub.number), signal

  score_snapshot: ->
    name: 'nobody'
    points: @points
    time: @duration
    naubs: @ex_naubs
    game_version: @version
    level: @levels?.level
    mode: @mode.id

  confirm_stop: -> confirm "Do you realy want to stop the game?"

