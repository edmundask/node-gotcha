_         = require 'underscore'
clone     = require 'clone'
Protocol  = require '../tcp'
Packet    = require '../packet'
log4js    = require 'log4js'
logger    = log4js.getLogger('[Murmur Protocol]')

class MurmurProtocol extends Protocol
  constructor: (@host, @port) ->
    super

    @packets.XML = 
      packet: '\x78\x6D\x6C'
      type: 'PACKET'
    @packets.JSON =
      packet: '\x6A\x73\x6F\x6E'
      type: 'PACKET'

    @logger = logger

    @logger.debug 'Protocol initialized'

    # Data
    @formatted_response = null
    @channels = []
    @users = []
    @channels_html = ''

  _parseInfoPacket: (packet) ->
    # Convert Buffer to string, then parse JSON and form the object
    @formatted_response = JSON.parse packet.toString()

    # Initiate channel parsing
    this._parseChannels(@formatted_response)
    this._channelsToHtml(@formatted_response.root.channels)

    # Assign parsed data to the final response package
    @formatted_response.channels = @channels
    @formatted_response.users = @users
    @formatted_response.html = @channels_html

    @formatted_response

  _parseChannels: (channels) ->
    _this = this

    # In order to preserve the original response data,
    # we need to clone the object
    channels_c = clone channels

    # We'll have to deal with the root channel separately
    if typeof channels.root != 'undefined'
      if channels_c.root.users.length > 0
        _.each channels_c.root.users, (user) ->
          _this.users.push user

      _this._parseChannels channels_c.root.channels
    else
      if channels_c.length > 0
        _.each channels_c, (channel) ->
          if channel.users.length > 0
            _.each channel.users, (user) ->
              _this.users.push user

          delete channel['users']
          _this._parseChannels channel.channels

          delete channel['channels']
          _this.channels.push channel

  _channelsToHtml: (channels, first = true) ->
    _this = this

    if channels.length > 0
      _this.channels_html += '<ul class="channels">'

      _.each channels, (channel) ->
        _this.channels_html += '<li class="channel">' + channel.name
        _this._channelsToHtml channel.channels, false

        _this._usersToHtml channel

        _this.channels_html += '</li>'

      _this.channels_html += '</ul>'

    if first
      # Append users that are in the root channel
      _this._usersToHtml _this.formatted_response.root

  _usersToHtml: (channel) ->
    _this = this

    if channel.users.length > 0
      _this.channels_html += '<ul class="users">'

      _.each channel.users, (user) ->

        if (user.selfMute && user.selfDeaf)
          classes = 'muted-deafened'
          title = 'Muted and deafened'
        else if (user.selfMute && !user.selfDeaf)
          classes = 'muted'
          title = 'Muted'
        else if (!user.selfMute && user.selfDeaf)
          classes = 'deafened'
          title = 'Deafened'
        else
          classes = ''
          title = 'Ready to mumble'

        _this.channels_html += '<li class="user ' + classes + '" title="' + title + '">' + user.name + '</li>'

      _this.channels_html += '</ul>'

  on: (msg, callback) ->
    super
    _this = this

    switch msg
      when 'info'
        this.sendPacket @packets.JSON.packet,
          ok: ->
            callback(_this._parseInfoPacket _this.response)

module.exports = MurmurProtocol