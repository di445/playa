"use babel";

var ipc = require('ipc')

var React = require('react')
var Tabs = require('react-simpletabs')
var _ = require('lodash')
var PlaybackBar = require('./player/PlaybackBar.jsx')
var Playlist = require('./playlist/Playlist.jsx')

var AppDispatcher = require('../dispatcher/AppDispatcher')

var PlaylistStore = require('../stores/PlaylistStore')
var PlayerStore = require('../stores/PlayerStore')

var PlaylistConstants = require('../constants/PlaylistConstants')
var PlaylistActions = require('../actions/PlaylistActions')

var Loader = require('../util/Loader')
var loader = new Loader()

ipc.on('playlist:create', function(){
  PlaylistActions.create()
})

ipc.on('playlist:clear', function(){
  AppDispatcher.dispatch({
    actionType: PlaylistConstants.CLEAR_PLAYLIST
  })  
})

function getPlaylistState(){
  return {
    playlists: PlaylistStore.getAll() || {},
    selectedPlaylist: PlaylistStore.getSelectedIndex()
  }  
}

function getPlayerState(){
  return {
    playbackInfo: PlayerStore.getPlaybackInfo() || {}
  }
}

module.exports = React.createClass({
  getInitialState: function() {
    return _.merge(getPlayerState(), getPlaylistState())
  },
  componentDidMount: function() {
    PlaylistStore.addChangeListener(this._onPlaylistChange)
    PlayerStore.addChangeListener(this._onPlayerChange)
    PlaylistActions.create()
    PlaylistActions.select(0)
    PlaylistActions.activate(0)
  },
  componentWillUnmount: function() {
    PlaylistStore.removeChangeListener(this._onPlaylistChange)
    PlayerStore.removeChangeListener(this._onPlayerChange)
  },  
  handleAfter: function(selectedIndex, $selectedPanel, $selectedTabMenu) {
    PlaylistActions.select(selectedIndex-1)
  },
  render: function() {   
    var playlists = this.state.playlists.map((playlist)=>{
      return (
        <Tabs.Panel title={playlist.title} key={playlist.title}>
          <Playlist className="playa-playlist-main" playlist={playlist}/>
        </Tabs.Panel>
      )
    })
    return (
      <div className="playa-main">
        <PlaybackBar playbackInfo={this.state.playbackInfo}/>
        <Tabs
          tabActive={this.state.selectedPlaylist+1}
          onAfterChange={this.handleAfter}>
          {playlists}
        </Tabs>
      </div>
    )
  },
  _onPlaylistChange: function() {
    this.setState(getPlaylistState())
  },
  _onPlayerChange: function(){
    this.setState(getPlayerState())
  }  
})