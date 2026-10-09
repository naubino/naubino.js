import {Naubino} from './Naubino'
import {Util} from './Util'
window.Util = Util
console.time("loading")

window.addEventListener "resize", -> Util.relayout() if window.Naubino?
window.addEventListener "orientationchange", -> Util.relayout(300) if window.Naubino?

window.onload = ->
  naubino = window.Naubino = new Naubino()
  naubino.setup()
  naubino.apply_color_scheme()
  document.querySelector("#highscorelink").addEventListener "click", -> confirm "do you want to leave this page?"

  matchMedia("(prefers-color-scheme: dark)").addEventListener "change", ->
    naubino.apply_color_scheme()

  if navigator.maxTouchPoints > 0 and matchMedia("(pointer: coarse)").matches
    document.documentElement.classList.add "touch"
    document.querySelector("#maximizeCheck").checked = true
    naubino.menu.open()


  Util.toggleMaximized()

  # reflect initial settings in the UI (settings are the source of truth on load)
  document.querySelector('#effectsCheck').checked = naubino.settings.graphics.effects == on


  #populate color selector
  colors_select = document.querySelector('select#colors')
  for name, _colors of naubino.settings.colors
    option = document.createElement('option')
    option.value = name
    option.textContent = name
    colors_select.appendChild option
  for option in document.querySelectorAll('select#colors option')
    option.selected = true if option.value == naubino.settings.color
  colors_select.addEventListener "change", ->
    naubino.settings.color = this.value
    if this.value == 'high_contrast'
      naubino.settings.graphics.draw_borders_old = naubino.settings.graphics.draw_borders
      naubino.settings.graphics.draw_borders = true
    else if naubino.settings.graphics.draw_borders_old?
      naubino.settings.graphics.draw_borders = naubino.settings.graphics.draw_borders_old
    naubino.apply_color_scheme()
    naubino.menu.for_each (naub) -> naub.recolor()
    naubino.game.for_each (naub) -> naub.recolor()
    naubino.game.draw()


  for event in ["fullscreenchange", "webkitfullscreenchange", "mozfullscreenchange"]
    document.addEventListener event, (-> Util.changeFullscreen()), false
