import {Rule} from '../Rule'

export class Levels extends Rule
  constructor: (game, @spawner, @level_details) ->
    super(game)

  init: -> @load_level 0

  load_level: (level) ->
    if @level_details.length >= level
      @load_level 0 if 0 < level < @level

      @level = level
      #Naubino.overlay.fade_in_and_out_message "Level #{@level}" unless level < 1
      #Naubino.menu.for_each (naub)->naub.set_random_palette_color() unless level < 2

      set = @level_details[@level]

      @game.basket.max_naubs    = set['max_naubs']        ? @game.basket.max_naubs
      @spawner.number_of_colors = set['number_of_colors'] ? @spawner.number_of_colors
      @spawner.spammer_interval = set['interval']         ? @spawner.spammer_interval

      @game.events.game.basket_changed.dispatch()

      for name, probability of set['probabilities']
        @spawner.spammers[name].probability = probability

  check: ->
    @load_level(@level+1) if @level_details[@level].limit < @game.ex_naubs
