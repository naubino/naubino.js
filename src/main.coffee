import {Naubino} from './Naubino'
import {Settings} from './config/Settings'
import {StandardMode} from './modes/standard/StandardMode'
import {DebugMode} from './modes/DebugMode'
import {StandardGame} from './game/StandardGame'
import {DebugGame} from './game/DebugGame'
import {Util} from './core/Util'
import {Controls} from './ui/Controls'
window.Util = Util
console.time("loading")


window.onload = ->
  Settings.load_from_search window.location.search
  {game_class, mode} = gameFromSearch window.location.search
  if navigator.maxTouchPoints > 0 and matchMedia("(pointer: coarse)").matches
    document.documentElement.classList.add "touch"
    document.querySelector("#maximizeCheck").checked = true

  maximize_check = document.querySelector '#maximizeCheck'
  layout_options = (fit = Util.isTouch()) ->
    maximized: maximize_check.checked or Util.isFullscreen()
    fit: fit

  naubino = window.Naubino = new Naubino(mode, '#gamediv', game_class)
  naubino.setup layout_options(true)
  naubino.apply_color_scheme()
  document.querySelector("#highscorelink").addEventListener "click", ->
    confirm "do you want to leave this page?"
  document.querySelector("#parameterslink").addEventListener "click", ->
    document.querySelector("#parametersdialog").showModal()
  document.querySelector("#closeparameters").addEventListener "click", ->
    document.querySelector("#parametersdialog").close()

  matchMedia("(prefers-color-scheme: dark)").addEventListener("change", -> naubino.apply_color_scheme())

  if Util.isTouch()
    naubino.menu.open()
    naubino.play()

  maximize_check.addEventListener 'change', -> naubino.viewport.layout layout_options(true)

  window.addEventListener 'resize', -> naubino.viewport.schedule_layout layout_options()

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
      naubino.settings.graphics.draw_borders = true
    naubino.apply_color_scheme()
    naubino.menu.for_each (naub) -> naub.recolor()
    naubino.game.for_each (naub) -> naub.recolor()
    naubino.game.draw()




gameFromSearch = (search = '') ->
  params = new URLSearchParams search
  switch params.get('mode')
    when 'debug' then return {game_class: DebugGame, mode: new DebugMode}
    else return {game_class: StandardGame, mode: new StandardMode}
