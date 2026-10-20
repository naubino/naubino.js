export class Signal extends EventTarget
  active: true

  add: (listener, context) =>
    handler = (e) -> listener.apply(context, e.detail)
    @addEventListener "dispatch", handler
    => @removeEventListener "dispatch", handler

  dispatch: (args...) =>
    @dispatchEvent new CustomEvent "dispatch", detail: args if @active
