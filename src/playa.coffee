_                         = require 'lodash'
md5                       = require 'md5'
ipc                       = require 'ipc'
path                      = require 'path'
React                     = require 'react'
Main                      = require './renderer/components/Main.jsx'
Player                    = require './renderer/util/Player'
AlbumPlaylist             = require './renderer/util/AlbumPlaylist'
PlaylistLoader            = require './renderer/util/PlaylistLoader'
FileLoader                = require './renderer/util/FileLoader'
CoverLoader               = require './renderer/util/CoverLoader'
WaveformLoader            = require './renderer/util/WaveformLoader'
AppDispatcher             = require './renderer/dispatcher/AppDispatcher'
PlayerConstants           = require './renderer/constants/PlayerConstants'
PlaylistBrowserConstants  = require './renderer/constants/PlaylistBrowserConstants'
OpenPlaylistConstants     = require './renderer/constants/OpenPlaylistConstants'
SidebarConstants          = require './renderer/constants/SidebarConstants'
PlayerStore               = require './renderer/stores/PlayerStore'
OpenPlaylistStore         = require './renderer/stores/OpenPlaylistStore'
SidebarStore              = require './renderer/stores/SidebarStore'
OpenPlaylistActions       = require './renderer/actions/OpenPlaylistActions'

require('dotenv').load()

module.exports = class Playa
  constructor: (options) ->
    @options = options
    @playlistLoader = new PlaylistLoader
      root: path.join @options.userDataFolder, 'Playlists'
      playlistExtension: 'm3u'
    @fileLoader = new FileLoader
      fileExtensions: ['mp3', 'mp4', 'flac', 'ogg']
    @coverLoader = new CoverLoader
      root: path.join @options.userDataFolder, 'Covers'
      discogs:
        key: process.env.DISCOGS_KEY
        secret: process.env.DISCOGS_SECRET
        throttle: 1000
    @waveformLoader = new WaveformLoader
      root: path.join @options.userDataFolder, 'Waveforms'
      config:
        'wait'              : 100,
        'png-width'         : 1600,
        'png-height'        : 160,
        'png-color-bg'      : '00000000',
        'png-color-center'  : '777777AA',
        'png-color-outer'   : '77777733'
    @player = new Player()
    @player.fileLoader = @fileLoader

    @player.on 'nowplaying', ->
      PlayerStore.emitChange()

    @player.on 'playerTick', ->
      PlayerStore.emitChange()

    OpenPlaylistStore.addChangeListener @_onOpenPlaylistChange

  init: ->
    @initIPC()
    @loadPlaylists()

  loadPlaylists: ->
    @playlistLoader.loadTree().then (tree)=>
      AppDispatcher.dispatch
        actionType: PlaylistBrowserConstants.LOAD_TREE
        tree: tree

    playlists = []

    if @options.sessionSettings.openPlaylists.length
      playlists = @options.sessionSettings.openPlaylists.map (i) ->
        new AlbumPlaylist({ id: md5(i), path: i })
    else
      playlists = [ new AlbumPlaylist({ title: 'Untitled', id: md5('Untitled.m3u') }) ]

    AppDispatcher.dispatch
      actionType: OpenPlaylistConstants.ADD_PLAYLIST
      playlists: playlists

    AppDispatcher.dispatch
      actionType: OpenPlaylistConstants.SELECT_PLAYLIST
      selected: @options.sessionSettings.selectedPlaylist or 0

  initIPC: ->
    ipc.on 'sidebar:show', (tab)->
      AppDispatcher.dispatch
        actionType: SidebarConstants.SELECT_TAB
        tab: tab

    ipc.on 'playback:prev', ->
      AppDispatcher.dispatch
        actionType: PlayerConstants.PREV

    ipc.on 'playback:next', ->
      AppDispatcher.dispatch
        actionType: PlayerConstants.NEXT

    ipc.on 'playback:toggle', =>
      AppDispatcher.dispatch
        actionType: if @player.playing() then PlayerConstants.PAUSE else PlayerConstants.PLAY

    ipc.on 'sidebar:toggle', ->
      AppDispatcher.dispatch
        actionType: SidebarConstants.TOGGLE

    ipc.on 'playlist:create', ->
      AppDispatcher.dispatch
        actionType: OpenPlaylistConstants.ADD_PLAYLIST
        playlists: [ new AlbumPlaylist({ title: 'Untitled', id: md5('Untitled.m3u') }) ]

    ipc.on 'playlist:save', ->
      AppDispatcher.dispatch
        actionType: OpenPlaylistConstants.SAVE_PLAYLIST

    ipc.on 'playlist:close', ->
      AppDispatcher.dispatch
        actionType: OpenPlaylistConstants.CLOSE_PLAYLIST

    ipc.on 'open:folder', (folder)->
      AppDispatcher.dispatch
        actionType: OpenPlaylistConstants.ADD_FOLDER
        folder: folder

  render: ->
    React.render React.createElement(Main), document.getElementById('main')

  _onOpenPlaylistChange: ->
    playlists = OpenPlaylistStore.getAll().filter((i) -> !i.isNew() ).map (i) -> i.path
    selectedPlaylist = OpenPlaylistStore.getSelectedIndex()
    if playlists.length then ipc.send 'session:save', key: 'openPlaylists', value: playlists
    if selectedPlaylist > -1 then ipc.send 'session:save', key: 'selectedPlaylist', value: selectedPlaylist
