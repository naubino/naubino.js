# TODO LEVEL UP
#   number of colors
#   number of naubs per spam
#   speed up
import {Mode} from '../Mode'

import {ConnectionAnalysis} from '../ConnectionAnalysis'
import {Basket} from './Basket'
import {BasketRenderer} from './BasketRenderer'
import {Spawner} from './Spawner'
import {Scoring} from './Scoring'

import {Levels} from './Levels'

export class StandardMode extends Mode
  default_parts: ->
    Object.assign {}, super(), {
      basket: ({world, field, loss_requested, config}) ->
        new Basket world, field, loss_requested, config.naub?.size
      spawner: ({factory, config}) -> new Spawner factory, config.spawn
      scoring: ({world, basket, naub_destroyed, cycle_found, score_changed, chain_bonus}) ->
        new Scoring world, basket, naub_destroyed, cycle_found, score_changed, chain_bonus
      levels: ({spawner, basket, progress, level_changed, config}) ->
        new Levels spawner, basket, progress, level_changed, config.level_details
      basket_renderer: ({basket, field}) -> new BasketRenderer basket, field
      connection_analysis: ({join_added, join_removed, naub_replaced, cycle_found}) ->
        new ConnectionAnalysis join_added, join_removed, naub_replaced, cycle_found
    }

  configuration: ->
    config = super()
    config.level_details ?= structuredClone @level_details
    config

  assemble: ({config, world, events, field, stage}) ->
    {loss_requested, naub_destroyed, cycle_found, score_changed, chain_bonus, level_changed,
      join_added, join_removed, naub_replaced} = events
    factory = @parts.factory {world, field, config}
    basket = @parts.basket {world, field, loss_requested, config}
    spawner = @parts.spawner {factory, config}
    scoring = @parts.scoring {world, basket, naub_destroyed, cycle_found, score_changed, chain_bonus}
    levels = @parts.levels {spawner, basket, progress: scoring, level_changed, config}
    basket_renderer = @parts.basket_renderer {basket, field}
    stage.add basket_renderer, -10
    connections = @parts.connection_analysis {join_added, join_removed, naub_replaced, cycle_found}
    abort_controller = new AbortController

    events.cycle_found.add ((ids) -> world.destroy_naubs ids), abort_controller.signal
    cycle_handling =
      dispose: -> abort_controller.abort()
    results =
      scoreboard: -> {points: scoring.points, level: levels.level}
      final: ->
        points: scoring.points
        time: scoring.duration
        naubs: scoring.cleared_naubs()
        level: levels.level
    rules = [spawner, scoring, basket, levels, connections, cycle_handling]
    {rules, results, connections, join_policy: @parts.join_policy {config}}

  level_details: [
    { limit:-1,    number_of_colors: 3, interval: 40, max_naubs: 20 } # initial state
    { limit:20,    number_of_colors: 3, interval: 38, max_naubs: 20, probabilities:{ pair:1, mixed_1:0, mixed_2:0, triple: 0 } } #1
    { limit:50,    number_of_colors: 3, interval: 36, max_naubs: 25, probabilities:{ pair:9, mixed_1:0, mixed_2:0, triple: 2 } } #2
    { limit:80,    number_of_colors: 4, interval: 30, max_naubs: 30, probabilities:{ pair:9, mixed_1:0, mixed_2:0, triple: 1 } } #3
    { limit:120,   number_of_colors: 4, interval: 25, max_naubs: 35, probabilities:{ pair:8, mixed_1:1, mixed_2:0, triple: 1 } } #4
    { limit:150,   number_of_colors: 5, interval: 25, max_naubs: 40, probabilities:{ pair:7, mixed_1:2, mixed_2:0, triple: 1 } } #5
    { limit:180,   number_of_colors: 5, interval: 29, max_naubs: 43, probabilities:{ pair:6, mixed_1:3, mixed_2:0, triple: 1 } } #6
    { limit:210,   number_of_colors: 6, interval: 30, max_naubs: 45, probabilities:{ pair:5, mixed_1:3, mixed_2:1, triple: 1 } } #7
    { limit:240,   number_of_colors: 6, interval: 33, max_naubs: 47, probabilities:{ pair:4, mixed_1:4, mixed_2:1, triple: 1 } } #8
    { limit:270,   number_of_colors: 7, interval: 36, max_naubs: 49, probabilities:{ pair:3, mixed_1:4, mixed_2:2, triple: 1 } } #9
    { limit:300,   number_of_colors: 7, interval: 28, max_naubs: 50, probabilities:{ pair:3, mixed_1:3, mixed_2:3, triple: 2 } } #10
    { limit:350,   number_of_colors: 7, interval: 24, max_naubs: 50, probabilities:{ pair:3, mixed_1:3, mixed_2:3, triple: 2 } } #11
    { limit:380,   number_of_colors: 7, interval: 22, max_naubs: 50, probabilities:{ pair:3, mixed_1:3, mixed_2:3, triple: 2 } } #12
    { limit:420,   number_of_colors: 7, interval: 20, max_naubs: 50, probabilities:{ pair:3, mixed_1:3, mixed_2:3, triple: 2 } } #13
    { limit:500,   number_of_colors: 7, interval: 15, max_naubs: 50, probabilities:{ pair:3, mixed_1:3, mixed_2:3, triple: 2 } } #14
  ]
