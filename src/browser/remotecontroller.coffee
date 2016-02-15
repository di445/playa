_               = require 'lodash'
path            = require 'path'
http            = require 'http'
express         = require 'express'
io              = require 'socket.io'
{EventEmitter}  = require 'events'

module.exports =
class RemoteController
  _.extend @prototype, EventEmitter.prototype

  constructor: (options={}) ->
    @started = false
    @defaultPort = 1337
    @port = options.port || @defaultPort
    @data =
      playlist: {}
      playbackInfo: {}
    @serverOpts =
      root: path.join __dirname, '../ui'
    @window = options.window

  isActive: =>
    @started

  start: ()=>
    @app = require('express')()
    @http = http.createServer @app
    @io = io @http
    @io.on 'connection', (socket) =>
      console.log 'New incoming connection'
      socket.emit 'data', @data
      socket.on 'control:playback', (data) =>
        switch data.action
          when 'toggle' then @window.togglePlayback()
          when 'prev' then @window.prevTrack()
          when 'next' then @window.nextTrack()
          when 'gotoAlbum' then @window.gotoAlbum data

    @app.use express.static @serverOpts.root
    @app.get '/remote', (req, res) =>
      res.sendFile 'remote.html', @serverOpts

    @app.get '/js/:file(*)', (req, res) =>
      res.sendFile path.resolve __dirname, '../../node_modules/', req.params.file

    @http.listen @port, =>
      console.info "Remote control listening at: #{@getAddress()}"

    @started = true

  stop: =>
    @http.close =>
      console.info 'Remote control stopped.'
    @started = false

  #TODO: check http://stackoverflow.com/a/9542157/1073758
  getAddress: =>
    "http://192.168.1.3:#{@port}"

  update: (data) =>
    _.assign @data, data
    @io.sockets.emit 'data', @data