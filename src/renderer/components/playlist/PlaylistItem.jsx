"use babel"

var React = require('react')
var ReactPropTypes = React.PropTypes
var PlaylistActions = require('../../actions/PlaylistActions')

var PlaylistItem = React.createClass({
  propTypes: {
    metadata: ReactPropTypes.object.isRequired
  },
  render: function() {
    return (
      <tr onDoubleClick={this.onDoubleClick} onClick={this.onClick}>
        <td className="text-center">{ this.props.metadata.track }</td>
        <td className="text-nowrap">{ this.props.metadata.artist }</td>
        <td className="text-nowrap">{ this.props.metadata.album }</td>
        <td className="text-nowrap">{ this.props.metadata.title }</td>
        <td className="text-center">{ this.props.metadata.date }</td>
      </tr>
    )
  },
  onDoubleClick: function(event){
    PlaylistActions.playFile(this.props.itemKey)
  },
  onClick: function(event){
    
  }
})

module.exports = PlaylistItem