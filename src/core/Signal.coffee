export class Signal extends EventTarget
  active: true

  add: (listener, abort_signal) =>
    handler = (event) -> listener event.detail...
    @addEventListener "dispatch", handler, {signal: abort_signal}
    => @removeEventListener "dispatch", handler

  dispatch: (args...) =>
    @dispatchEvent new CustomEvent "dispatch", detail: args if @active
