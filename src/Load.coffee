import {Naubino} from './Naubino'
import {Util} from './Util'
console.time("loading")

window.onresize = ->
  if $("#maximizeCheck").is(":checked")
    clearTimeout window.resizetimeout if window.resizetimeout?
    window.resizetimeout = setTimeout (
      ->
        window.Naubino.maximize()
        window.Naubino.center()
    ) , 1000
  else
    window.Naubino.center()

window.onload = ->
  naubino = window.Naubino = new Naubino()
  naubino.setup()
  $("#highscorelink").on "click", -> confirm "do you want to leave this page?"

  if navigator.platform.indexOf("iPad") != -1
    $("#maximizeCheck").prop "checked", true
    $("#github").hide()
    $("form label").hide()
    $("form input[type=checkbox]").hide()
    


  Util.toggleMaximized()


  #populate color selector
  for name, colors of naubino.settings.colors then $('select#colors').append("<option value=\"#{name}\">#{name}</option>")
  $('select#colors option').each (index,option) -> if option.value == naubino.settings.color then option.selected = true
  $('select#colors').change ->
    naubino.settings.color = this.value
    if this.value == 'high_contrast'
      naubino.settings.graphics.draw_borders_old = naubino.settings.graphics.draw_borders
      naubino.settings.graphics.draw_borders = true
    else if naubino.settings.graphics.draw_borders_old?
      naubino.settings.graphics.draw_borders = naubino.settings.graphics.draw_borders_old
    naubino.menu.for_each (naub) -> naub.recolor()
    naubino.game.for_each (naub) -> naub.recolor()
    naubino.game.draw()


  document.addEventListener("fullscreenchange",       ( => Util.changeFullscreen (document.fullscreen)         ), false)
  document.addEventListener("mozfullscreenchange",    ( => Util.changeFullscreen (document.mozFullScreen)      ), false)
  document.addEventListener("webkitfullscreenchange", ( => Util.changeFullscreen (document.webkitIsFullScreen) ), false)




