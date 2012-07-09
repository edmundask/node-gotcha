require 'buffertools'

Protocol  = require '../protocol'
Packet    = require '../packet'
log4js    = require 'log4js'
logger    = log4js.getLogger '[Source Protocol]'
UTF8      = require '../utf8'
utf8      = new UTF8

class SourceProtocol extends Protocol
  constructor: (@host, @port) ->
    super

    @packets.CHALLENGE =
     packet: new Buffer('FFFFFFFF5600000000', 'hex')
     type: 'CHALLENGE'
    @packets.PLAYERS = 
      packet: new Buffer('FFFFFFFF55', 'hex')
      type: 'WITH_CHALLENGE'
    @packets.INFO = 
      packet: new Buffer('FFFFFFFF54536F7572636520456E67696E6520517565727900', 'hex')
      type: 'PACKET'
    @packets.RULES = 
      packet: new Buffer('FFFFFFFF56', 'hex')
      type: 'WITH_CHALLENGE'

    @logger = logger

    @logger.debug 'Protocol initialized'

  _parseChallenge: (buffer) ->
    @logger.trace 'Parsing received challenge...'

    packet = new Packet(buffer)
    packet.skip 5

    challenge = packet.read 4
    @challenge = new Buffer(challenge)

  _parsePlayersPacket: (buff) ->
    packet = new Packet(buff)

    # Skip header bytes
    packet.skip 5

    players = 
      count: packet.getByte()
      list: []

    i = 1
    while packet.getPos() < buff.length

      # Skip one byte since ID value is always 0
      packet.skip 1

      player =
        id:     i
        name:   packet.getString()
        score:  packet.getLong()
        time:   Math.round(packet.getFloat())

      players.list.push player
      i++

    players

  _parseInfoPacket: (buff) ->
    packet = new Packet(buff)

    # Skip header bytes
    packet.skip 5

    info =
      version:      packet.getByte()
      serverName:   packet.getString()
      map:          packet.getString()
      gameDir:      packet.getString()
      gameDesc:     packet.getString()
      appId:        packet.getShort()
      players:      packet.getByte()
      maxPlayers:   packet.getByte()
      botNumber:    packet.getByte()
      dedicated:    String.fromCharCode packet.getByte()
      os:           String.fromCharCode packet.getByte()
      passwordProt: packet.getByte() == 1
      secureServer: packet.getByte() == 1
      gameVersion:  packet.getString()

    info

  on: (msg, callback) ->
    super
    _this = this

    switch msg
      when 'players'
        this.sendPacket @packets.CHALLENGE.packet,
          ok: ->
            _this.sendPacket _this.packets.PLAYERS.packet.concat(_this._parseChallenge(_this.response)),
              ok: ->
                _this.logger.info 'Players packet received.'
                callback(_this._parsePlayersPacket _this.response)
      when 'info'
        this.sendPacket @packets.INFO.packet,
          ok: ->
            _this.logger.info 'INFO packet received.'
            callback(_this._parseInfoPacket _this.response)

module.exports = SourceProtocol