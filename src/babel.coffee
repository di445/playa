###
Cache for source code transpiled by babel.

Inspired by https://github.com/atom/atom/blob/6b963a562f8d495fbebe6abdbafbc7caf705f2c3/src/coffee-cache.coffee.
###

crypto = require 'crypto'
fs = require 'fs-plus'
path = require 'path'
babel = require 'babel-core'

stats =
  hits: 0
  misses: 0

defaultOptions =
  # The Chrome dev tools will show the original version of the file
  # when the source map is inlined.
  sourceMap: 'inline'

###
shasum - Hash with an update() method.
value - Must be a value that could be returned by JSON.parse().
###
updateDigestForJsonValue = (shasum, value) ->
  # Implmentation is similar to that of pretty-printing a JSON object, except:
  # * Strings are not escaped.
  # * No effort is made to avoid trailing commas.
  # These shortcuts should not affect the correctness of this function.
  type = typeof value
  if type is 'string'
    shasum.update('"', 'utf8')
    shasum.update(value, 'utf8')
    shasum.update('"', 'utf8')
  else if type in ['boolean', 'number']
    shasum.update(value.toString(), 'utf8')
  else if value is null
    shasum.update('null', 'utf8')
  else if Array.isArray value
    shasum.update('[', 'utf8')
    for item in value
      updateDigestForJsonValue(shasum, item)
      shasum.update(',', 'utf8')
    shasum.update(']', 'utf8')
  else
    # value must be an object: be sure to sort the keys.
    keys = Object.keys value
    keys.sort()

    shasum.update('{', 'utf8')
    for key in keys
      updateDigestForJsonValue(shasum, key)
      shasum.update(': ', 'utf8')
      updateDigestForJsonValue(shasum, value[key])
      shasum.update(',', 'utf8')
    shasum.update('}', 'utf8')

createBabelVersionAndOptionsDigest = (version, options) ->
  shasum = crypto.createHash('sha1')
  # Include the version of babel in the hash.
  shasum.update('babel-core', 'utf8')
  shasum.update('\0', 'utf8')
  shasum.update(version, 'utf8')
  shasum.update('\0', 'utf8')
  updateDigestForJsonValue(shasum, options)
  shasum.digest('hex')

cacheDir = path.join(fs.absolute('~/.atom'), 'compile-cache')
jsCacheDir = path.join(
  cacheDir,
  createBabelVersionAndOptionsDigest(babel.version, defaultOptions),
  'js')

getCachePath = (sourceCode) ->
  digest = crypto.createHash('sha1').update(sourceCode, 'utf8').digest('hex')
  path.join(jsCacheDir, "#{digest}.js")

getCachedJavaScript = (cachePath) ->
  if fs.isFileSync(cachePath)
    try
      cachedJavaScript = fs.readFileSync(cachePath, 'utf8')
      stats.hits++
      return cachedJavaScript
  null

# Returns the babel options that should be used to transpile filePath.
createOptions = (filePath) ->
  options = filename: filePath
  for key, value of defaultOptions
    options[key] = value
  options

# Function that obeys the contract of an entry in the require.extensions map.
# Returns the transpiled version of the JavaScript code at filePath, which is
# either generated on the fly or pulled from cache.
loadFile = (module, filePath) ->
  sourceCode = fs.readFileSync(filePath, 'utf8')
  unless /^("use 6to5"|'use 6to5'|"use babel"|'use babel')/.test(sourceCode)
    module._compile(sourceCode, filePath)
    return

  cachePath = getCachePath(sourceCode)
  js = getCachedJavaScript(cachePath)

  unless js
    options = createOptions filePath
    try
      js = babel.transform(sourceCode, options).code
      stats.misses++
    catch error
      console.error('Error compiling %s: %o', filePath, error)
      throw error

    try
      fs.writeFileSync(cachePath, js)
    catch error
      console.error('Error writing to cache at %s: %o', cachePath, error)
      throw error

  module._compile(js, filePath)

register = ->
  Object.defineProperty(require.extensions, '.js', {
    writable: false
    value: loadFile
  })

module.exports =
  register: register
  getCacheMisses: -> stats.misses
  getCacheHits: -> stats.hits

  # Visible for testing.
  createBabelVersionAndOptionsDigest: createBabelVersionAndOptionsDigest
