fs    = require 'fs'
path  = require 'path'
topo  = require 'toposort'
async = require 'async'
_     = require 'lodash'

each_file = (dir, cb) ->
  _.chain fs.readdirSync(dir)
    .filter (fn) ->
      fn.match /\.(js|coffee)$/
    .map (fn) ->
      path.resolve path.join dir, fn
    .each cb

extract_arguments = (func) ->
  match = func.toString().match /function.*?\(([\s\S]*?)\)/
  if not match? then throw new Error "could not parse function arguments: #{func?.toString()}"
  deps = _.filter(match[1].split(',')).map (s) -> s.trim()
  deps[...-1]

class Container
  constructor: ->
    @index = {}
    @arguments = {}

  register: (name, func) ->
    @index[name] =
      func: func
      args: extract_arguments(func)

  sorted_order: ->
    deps = _.chain @index
      .map (idx, name) ->
        idx.args.map (dep) ->
          [dep, name]
      .flatten true
    topo.array _.keys(@index), deps.value()

  load: (cb) ->
    data = {}
    series = _.map @sorted_order(), (name) =>
      idx = @index[name]
      (callback) ->
        args = idx.args.map (dep) ->
          data[dep]
        args.push (res) ->
          data[name] = res
          callback(null, res)
        idx.func.apply(null, args)
    async.series series, (err, results) ->
      cb(data)

module.exports = (dir, cb = _.noop) ->
  container = new Container()
  each_file dir, (fn) ->
    ext = path.extname fn
    name = path.basename(fn, ext)
    container.register name, require(fn)
  container.load(cb)

