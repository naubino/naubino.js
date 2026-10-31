import {Rule} from './Rule'

export class Spawner extends Rule

  init: ->
    @number_of_colors = @default_number_of_colors = 3

    @spammers = {
      pair:
        method: => @game.factory.create_naub_pair(null, @max_color(), @max_color() )
        probability: 5
      mixed_1:
        method: => @game.factory.create_naub_pair(null, @max_color(), @max_color(), 1 )
        probability: 0
      mixed_2:
        method: => @game.factory.create_naub_pair(null, @max_color(), @max_color(), 2 )
        probability: 0
      triple:
        method: => @game.factory.create_naub_triple(null, @max_color(), @max_color(), @max_color() )
        probability: 0
    }

    @inner_clock = 0 # to avoid resetting timer after pause

  start: ->
    @spamming = setInterval @event, 100 unless @spamming

  stop: ->
    clearInterval @spamming
    @spamming = null

  max_color: -> Math.floor(Math.random() * (@number_of_colors))

  #maps spammers to their probabilities
  map_spammers: ->
    sum = 0
    for name, spammer of @spammers
      sum += spammer.probability
      {range:sum,  name, method:spammer.method}

  #picks a random spammer according to its probability
  spam: ->
    probabilities = for name, spam of @spammers
      spam.probability
    max = probabilities.reduce (f,s) -> f+s
    dart = Math.floor(Math.random() * max)
    for spammer in @map_spammers()
      if dart < spammer.range
        spammer.method()
        return

  # recurring event (@spamming)
  event: =>
    @spam() if @inner_clock == 0
    @inner_clock = (@inner_clock + 1) % @spammer_interval
    @spammer_interval
