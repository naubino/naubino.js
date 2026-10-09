import {Util} from './Util'

export BLACK = [0,  0,  0, 1, "black"]
export WHITE = [255,  255,  255, 1, "white"]

export class ColorScheme
    constructor: (@naubs, light = {}, dark = {}) ->
        @light =
            background: light.background ? WHITE
            foreground: light.foreground ? BLACK
        @dark =
            background: dark.background ? @light.foreground
            foreground: dark.foreground ? @light.background

    background: -> if Util.isDarkMode() then @dark.background else @light.background
    foreground: -> if Util.isDarkMode() then @dark.foreground else @light.foreground
