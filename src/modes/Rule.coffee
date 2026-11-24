export class Rule
  constructor: (@game) ->
    @disposed = no

  dispose: -> @disposed = yes
