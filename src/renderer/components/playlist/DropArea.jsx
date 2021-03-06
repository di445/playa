"use babel"

var _ = require('lodash')
var path = require('path')
var shell = require('shell')
var React = require('react')
var ReactDOM = require('react-dom')
var ReactPropTypes = React.PropTypes
var cx = require('classnames')

var DragSource = require('react-dnd').DragSource
var DropTarget = require('react-dnd').DropTarget
var NativeTypes = require('react-dnd/modules/backends/HTML5').NativeTypes
var DragDropConstants = require('../../constants/DragDropConstants')

const _normaliseDroppedFolder = function(files){
  var folders
  return _(files)
    .filter( f => !f.type ).map( f => f.path )
    .tap( f => folders = f )
    .sortBy( f => f.split(path.sep).length )
    .filter( f => folders.filter( _f => (_f.indexOf(f) == 0) && (f !== _f) ).length == 0 ).value()
}

const dropAreaTarget = {
  drop(props, monitor, component) {
    var sourceItem = monitor.getItem()
    sourceItem.files && (sourceItem.source = NativeTypes.FILE)
    switch(sourceItem.source){
      case DragDropConstants.FILEBROWSER_FOLDER:
        props.handleFolderDrop(sourceItem.node.path)
        break
      case DragDropConstants.PLAYLIST_ALBUM:
        const draggedId = monitor.getItem().id
        props.moveAlbum(draggedId, null, 'after')
        break
      case NativeTypes.FILE:
        var folder = _normaliseDroppedFolder(sourceItem.files)
        folder && props.handleFolderDrop(folder)
        break
    }
    props.handleDragEnd()
  },
  hover(props, monitor, component) {
    ReactDOM.findDOMNode(component).classList.add('over')
  }
}

var DropArea = React.createClass({
  render: function() {
    var classes = cx({
      'drop-area' : true
    })
    var style = {
      height: this.props.height
    }
    return this.props.connectDropTarget(
      <div className={classes} style={style}>
        <span className="text">Drop albums here!</span>
      </div>
    )
  }
})
DropArea = DropTarget([
    DragDropConstants.PLAYLIST_ALBUM,
    DragDropConstants.FILEBROWSER_FOLDER,
    NativeTypes.FILE
  ], dropAreaTarget, connect => ({
  connectDropTarget: connect.dropTarget(),
}))(DropArea)

module.exports = DropArea
