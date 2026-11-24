export class Mode
  constructor: (@config = {}) ->

  configuration: -> structuredClone @config

  assemble: -> {rules: []}
