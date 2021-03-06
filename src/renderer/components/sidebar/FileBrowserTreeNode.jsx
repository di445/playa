"use babel"

var _ = require('lodash')
var cx = require('classnames')
var React = require('react')
var ReactPropTypes = React.PropTypes
var DragSource = require('react-dnd').DragSource
var TreeView = require('react-treeview')

var DragDropConstants = require('../../constants/DragDropConstants')

const fileBrowserTreeNodeSource = {
  beginDrag(props) {
    return {
      id: props.itemKey,
      originalIndex: props.index,
      node: props.node,
      source: DragDropConstants.FILEBROWSER_FOLDER
    }
  },
  endDrag(props, monitor) {

  }
}

var FileBrowserTreeNode = React.createClass({
  renderNodeArrow: function(){
    var classes = cx({
      'node-arrow'  : true
    })
    return (
      <span onClick={this.handleArrowClick} className={classes}></span>
    )
  },
  renderNodeLabel: function(){
    var classes = cx({
      'node-label': true
    })
    var iconClasses = cx({
      'fa' : true,
      'fa-fw' : true,
      'fa-folder': this.props.node.isDirectory(),
      'fa-file-audio-o' : this.props.node.extension == playa.getSetting('common', 'playlistExtension')
    })
    return (
      <span className={classes}>
        <i className={iconClasses}></i> {this.props.node.name}
      </span>
    )
  },
  render: function(){
    var node = this.props.node
    var classes = cx({
      'browser-node'  : true,
      'selected'      : this.props.isSelected,
      'collapsed'     : this.props.collapsed,
      'has-arrow'     : node.isDirectory()
    })
    var style = {
      paddingLeft: ( node.depth * 1 + ( node.isDirectory() ? 0 : 1.25) + 0.5 )+ 'rem'
    }
    return this.props.connectDragSource(
      <li
        data-id={node.id}
        style={style}
        className={classes}
        onClick={this.handleClick}
        onDoubleClick={this.handleDoubleClick}
        onContextMenu={this.handleContextMenu}>
        { node.isDirectory() ? this.renderNodeArrow() : null }
        { this.renderNodeLabel() }
      </li>
    )
  },
  handleClick: function(event){
    this.props.handleClick && this.props.handleClick(event, this)
  },
  handleDoubleClick(event){
    this.props.handleDoubleClick && this.props.handleDoubleClick(event, this)
  },
  handleContextMenu(event){
    this.props.handleContextMenu && this.props.handleContextMenu(event, this)
  },
  handleArrowClick(event){
    event.stopPropagation()
    this.props.handleArrowClick(event, this)
  }
})

FileBrowserTreeNode = DragSource(DragDropConstants.FILEBROWSER_FOLDER, fileBrowserTreeNodeSource, (connect, monitor) => ({
  connectDragSource: connect.dragSource(),
  isDragging: monitor.isDragging()
}))(FileBrowserTreeNode)

module.exports = FileBrowserTreeNode
