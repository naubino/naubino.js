import {Factory} from '../game/Factory'
import {JoinPolicy} from '../game/JoinPolicy'

export class Mode
  constructor: (@config = {}, overrides = {}) ->
    default_parts = @default_parts()
    for name in Object.keys overrides
      throw Error "Unknown part '#{name}' for #{@constructor.name}" unless Object.hasOwn default_parts, name
    @parts = Object.assign {}, default_parts, overrides

  default_parts: ->
    factory: ({world, field, config}) -> new Factory world, field, config
    join_policy: ({config}) -> new JoinPolicy config.game

  configuration: -> structuredClone @config

  assemble: -> {rules: []}
