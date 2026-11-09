import {Util} from '../core/Util'

export BLACK = [0,  0,  0, 1, "black"]
export WHITE = [255,  255,  255, 1, "white"]

export class ColorScheme
  constructor: ({@naubs, light = {}, dark = {}, warn = 0}) ->
    @warn = switch typeof warn
      when "number" then @naubs[warn]
      when "string" then @naubs.find(([_r,_g,_b,_a, name]) -> name is warn)
      else throw new Error("Invalid warn value: #{warn}")

    console.info(@warn)

    @light =
      background: light.background ? WHITE
      foreground: light.foreground ? BLACK
    @dark =
      background: dark.background ? @light.foreground
      foreground: dark.foreground ? @light.background

    @light_palette = @build_palette("light")
    @dark_palette = @build_palette("dark")

  background: -> if Util.isDarkMode() then @dark.background else @light.background
  foreground: -> if Util.isDarkMode() then @dark.foreground else @light.foreground

  palette: -> if Util.isDarkMode() then @dark_palette else @light_palette

  build_palette: (prefer = "light") ->
      byName = new Map
      brightness = ([r, g, b]) -> r + g + b

      for color in @naubs
        name = color[4] || "#{color[0]}, #{color[1]}, #{color[2]}, #{color[3]}"
        current = byName.get(name)
        if not current?
          byName.set(name, color)

        else if prefer == "dark" && brightness(color) > brightness(current)
          console.warn("found a brighter color for #{name}: #{color} vs #{current}")
          byName.set(name, color)

        else if prefer == "light" && brightness(color) < brightness(current)
          console.warn("found a darker color for #{name}: #{color} vs #{current}")
          byName.set(name, color)

      Array.from(byName.values())
