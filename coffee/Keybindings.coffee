class KeyBindings
    constructor: ->
        # down, up, during
        @bindings = {
        }
        @active_bindings = {
        }

    enable: (key, down, up, during) =>
        @bindings[key] =
            down: down
            up: up
            during: during

    disable: (key) =>
        active_binding = @active_bindings[key]
        # if key is pressed, call up()
        @bindings[key]?.up?()
        delete @bindings[key]
        delete @active_bindings[key]

    step: (dt) =>
        for own i of @active_bindings
            during = @active_bindings[i].during?(dt)
            @active_bindings[i].called = true

    keydown: (key) =>
        k = key.which
        console.log("keydown", k)
        if k of @bindings && !(k of @active_bindings)
            @bindings[k].down?()
            @active_bindings[k] =
                during: @bindings[k].during
                called: false

    keyup: (key) =>
        k = key.which
        if k of @active_bindings
            {during:during, called:called} = @active_bindings[k]
            during?() if not called
            # call during() at least once between down() and up()
            delete @active_bindings[k]
            @bindings[k].up?()

