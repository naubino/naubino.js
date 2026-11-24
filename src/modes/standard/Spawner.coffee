import {Rule} from '../Rule'

export class Spawner extends Rule
  constructor: (@factory, parameters = {}) ->
    super()
    @number_of_colors = 3
    @spammer_interval = 40
    @spammers =
      pair:
        method: => @factory.create_naub_pair null, @max_color(), @max_color()
        probability: 5
      mixed_1:
        method: => @factory.create_naub_pair null, @max_color(), @max_color(), 1
        probability: 0
      mixed_2:
        method: => @factory.create_naub_pair null, @max_color(), @max_color(), 2
        probability: 0
      triple:
        method: => @factory.create_naub_triple null, @max_color(), @max_color(), @max_color()
        probability: 0
    @inner_clock = 0
    @configure parameters

  configure: (parameters) ->
    @number_of_colors = parameters.number_of_colors if parameters.number_of_colors?
    @spammer_interval = parameters.interval if parameters.interval?
    for name, probability of parameters.probabilities
      @spammers[name].probability = probability
    return

  activate: -> @spam() unless @disposed

  start: ->
    return if @disposed
    @spamming = setInterval @event, 100 unless @spamming

  stop: ->
    clearInterval @spamming
    @spamming = null

  dispose: ->
    @stop()
    super()

  max_color: -> Math.floor Math.random() * @number_of_colors

  map_spammers: ->
    sum = 0
    for name, spammer of @spammers
      sum += spammer.probability
      {range: sum, name, method: spammer.method}

  spam: ->
    return if @disposed
    probabilities = (spammer.probability for name, spammer of @spammers)
    maximum = probabilities.reduce (total, probability) -> total + probability
    dart = Math.floor Math.random() * maximum
    for spammer in @map_spammers()
      if dart < spammer.range
        spammer.method()
        return

  event: =>
    return if @disposed or not @spamming?
    @spam() if @inner_clock == 0
    @inner_clock = (@inner_clock + 1) % @spammer_interval
    @spammer_interval
