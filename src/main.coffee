import {Naubino} from './Naubino'
import {StandardMode} from './modes/standard/StandardMode'
import {DebugMode} from './modes/DebugMode'
import {Util} from './core/Util'
import {Controls} from './ui/Controls'
window.Util = Util
console.time("loading")


window.onload = ->
  mode = modeFromSearch window.location.search
  naubino = window.Naubino = new Naubino mode
  naubino.setup()
  naubino.apply_color_scheme()
  document.querySelector("#highscorelink").addEventListener "click", -> confirm "do you want to leave this page?"

  matchMedia("(prefers-color-scheme: dark)").addEventListener "change", ->
    naubino.apply_color_scheme()

  if navigator.maxTouchPoints > 0 and matchMedia("(pointer: coarse)").matches
    document.documentElement.classList.add "touch"
    document.querySelector("#maximizeCheck").checked = true
    naubino.menu.open()
    naubino.play()

  maximize_check = document.querySelector '#maximizeCheck'

  layout_options = (fit = Util.isTouch()) ->
    maximized: maximize_check.checked or Util.isFullscreen()
    fit: fit

  maximize_check.addEventListener 'change', -> naubino.viewport.layout layout_options(true)

  window.addEventListener 'resize', -> naubino.viewport.schedule_layout layout_options()
  window.addEventListener 'orientationchange', -> naubino.viewport.schedule_layout layout_options(), 300

  naubino.viewport.layout layout_options(true)

  new Controls(naubino, on_layout: ->
    naubino.viewport.layout layout_options(true)
    naubino.viewport.schedule_layout layout_options()
  ).bind()


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




modeFromSearch = (search = '') ->
  params = new URLSearchParams search
  switch params.get('mode')
    when 'debug' then new DebugMode
    when null, 'standard' then new StandardMode
    else new StandardMode
