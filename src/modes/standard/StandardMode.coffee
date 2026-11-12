# TODO LEVEL UP
#   number of colors
#   number of naubs per spam
#   speed up
import {Mode} from '../Mode'
import {Spawner} from './Spawner'
import {Scoring} from './Scoring'
import {Overflow} from './Overflow'
import {Levels} from './Levels'
import {Basket} from './Basket'

export class StandardMode extends Mode
  id: 'standard'
  version: 2 # please raise when makeing changes to this file

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

  rules: (game) ->
    game.basket  = new Basket game
    game.spawner  = new Spawner game
    game.scoring  = new Scoring game
    game.overflow = new Overflow game
    game.levels   = new Levels game, game.spawner, @level_details
    # order matters: Levels writes into Spawner so it inits after it
    # and the lose check has to run before a level up grows the basket
    [game.spawner, game.scoring, game.overflow, game.levels]

  result: (game) ->
    name: 'nobody'
    points: game.points
    time: game.duration
    naubs: game.ex_naubs
    game_version: game.version
    level: game.levels?.level
    mode: @id

  init: (game) ->
    game.naub_replaced.add   (number) -> game.graph.cycle_test(number)
    game.cycle_found.add     (list)   -> game.destroy_naubs(list)
    game.naub_focused.add    (n)      -> game.active_tree = game.graph.tree n.number

    #Naubino.audio.connect_to_game game

  bind: (game, events) ->
    events.input.two_finger_tap.add -> events.commands.toggle.dispatch()

  confirm_stop: -> confirm "Do you realy want to stop the game?"
