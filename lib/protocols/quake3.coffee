_         = require 'underscore'
Protocol  = require '../protocol'
Packet    = require '../packet'
log4js    = require 'log4js'
logger    = log4js.getLogger('[Quake3 Protocol]')

class Quake3Protocol extends Protocol
  constructor: (@host, @port) ->
    super

    @packets.INFO = 
      packet: new Buffer('FFFFFFFF6765747374617475730A', 'hex')
      type: 'PACKET'

    @logger = logger

    @logger.debug 'Protocol initialized'

    @settings.timeout = 400

  _parsePacket: (buff, return_value = 'info') ->
    packet = new Packet(buff)

    players = 
      count: 0
      list: []

    info = {}

    # Skip header bytes
    packet.skip 4
    # Skip status response (we'll asume it's correct)
    packet.skip 14
    # Skip additional 2 bytes which are useless anyway
    packet.skip 2

    # Get server info portion of the response
    info_raw = packet.getString(0x0A)

    # Split the string by '\' symbol into an array
    keys = info_raw.split('\\')

    # Pair each key with according value
    i = 0
    for item in keys
      if typeof keys[i+1] != 'undefined'
        info[keys[i]] = keys[i+1]
        i++

      i++

    # Run through the buffer to get the list of players
    while packet.getPos() < buff.length

      player = 
        score: packet.getString(0x20)
        ping: packet.getString(0x20)
        name: packet.getString(0x0A)

      players.list.push player

    players.count = players.list.length

    return_value:
      info: info
      players: players

  on: (msg, callback) ->
    super
    _this = this

    switch msg
      when 'info'
        this.sendPacket @packets.INFO.packet,
          ok: ->
            callback(_this._parsePacket _this.response)

module.exports = Quake3Protocol