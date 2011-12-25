fs = require 'fs'
obf = require 'node-obf'

readfile = (filename, callback) ->
  fs.readFile filename, 'ASCII', (err, data) ->
    throw err if err
    if callback?
      callback(data)

obfuscate = (data, callback) ->
  obf = obf.obfuscate('N', data)
  if callback?
    callback(obf)

readfile('./Naubino.min.js', (data) -> obfuscate(data, console.log))
#readfile('./Naubino.min.js', console.log)
