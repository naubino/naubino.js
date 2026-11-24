import {Rule} from '../Rule'

export class Levels extends Rule
  constructor: (@spawner, @basket, @progress, @basket_changed, @level_changed, @level_details) ->
    super()
    @load_level 0

  load_level: (level) ->
    return if @disposed
    return unless 0 <= level < @level_details.length
    @load_level 0 if 0 < level < @level
    @level = level
    parameters = @level_details[level]
    @spawner.configure parameters
    @basket.set_capacity parameters.max_naubs if parameters.max_naubs?
    @basket_changed.dispatch @basket.basket_size()
    @level_changed.dispatch @level
    return

  start: -> @basket_changed.dispatch @basket.basket_size() unless @disposed

  check: ->
    return if @disposed
    return if @level >= @level_details.length - 1
    @load_level(@level + 1) if @level_details[@level].limit < @progress.cleared_naubs()
