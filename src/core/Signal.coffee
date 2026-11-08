export class Signal extends EventTarget
  active: true

  add: (listener, context) =>
    @addEventListener "dispatch", (e) -> listener.apply(context, e.detail)

  dispatch: (args...) =>
    @dispatchEvent new CustomEvent "dispatch", detail: args if @active
