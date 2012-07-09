Protocol  = require '../protocol'
Packet    = require '../packet'
log4js    = require 'log4js'
logger    = log4js.getLogger('[GameSpy2 Protocol]')
UTF8      = require '../utf8'
utf8      = new UTF8

class GameSpy2Protocol extends Protocol
  constructor: (@host, @port) ->
    super

    @packets.PLAYERS = 
      packet: new Buffer('FEFD00434F525900FFFF', 'hex')
      type: 'PACKET'
    @packets.INFO = 
      packet: new Buffer('FEFD00434F5259FF0000', 'hex')
      type: 'PACKET'

    @logger = logger

    @logger.debug 'Protocol initialized'

  _parsePlayersPacket: (buff) ->
    packet = new Packet(buff)

    players = 
      count: 0
      list: []

    # Skip header
    packet.skip 5

    # For the players packet, we need to skip additional 2 bytes
    packet.skip 2

    # Also skip the identifying value names
    packet.getString()
    packet.getString()
    packet.getString()

    # Hop over one more extra byte
    packet.skip 1

    while packet.getPos() < buff.length

      player =
        name:   packet.getString()
        score:  packet.getString()
        ping:   packet.getString()

      players.list.push player

    players.list.pop 1
    players.count = players.list.length

    players

  _parseInfoPacket: (buff) ->
    packet = new Packet(buff)

    # Skip header bytes
    packet.skip 5

    info = {}

    while packet.getPos() < buff.length-1

      attribute = packet.getString()
      info[attribute] = packet.getString()

    info

  on: (msg, callback) ->
    super
    _this = this

    switch msg
      when 'players'
        this.sendPacket @packets.PLAYERS.packet,
          ok: ->
              #_this.logger.info 'Players packet received.'
              callback(_this._parsePlayersPacket _this.response)
      when 'info'
        this.sendPacket @packets.INFO.packet,
          ok: ->
            #_this.logger.info 'INFO packet received.'
            callback(_this._parseInfoPacket _this.response)

module.exports = GameSpy2Protocol