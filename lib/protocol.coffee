dgram   = require 'dgram'
log4js  = require 'log4js'
logger  = log4js.getLogger('[protocol]')

class Protocol
  constructor: (@host, @port) ->
    # Packets (here we define them just as placeholders)
    @packets =
      CHALLENGE:
        packet: null
        type: 'PACKET'
      PLAYERS:
        packet: null
        type: 'PACKET'
      INFO:
        packet: null
        type: 'PACKET'
      RULES:
        packet: null
        type: 'PACKET'
      TEAMS:
        packet: null
        type: 'PACKET'

    @settings =
      timeout: 300

    # Active UDP socket
    @socket = null

    # Logger instance
    @logger = logger

    # Reply from the server (received packet)
    @response = null

    # Received challenge
    @challenge = null

    @online = false

    @callbacks = 
      offline: (->)

  sendPacket: (packet, options) ->
    @socket = dgram.createSocket('udp4')

    # This is to fix issues with scoping
    [_response, _logger, _socket, _settings, _this] = [@response, @logger, @socket, @settings, this]

    options.ok = options.ok || (->)
    options.error = options.error || (->)

    _logger.trace 'Sending packet...'

    @socket.send packet, 0, packet.length, @port, @host, (err, bytes) ->
      _logger.debug 'Packet sent with '+ bytes + ' bytes of data to ' + _this.host + ':' + _this.port + '.'

    @socket.on 'error', (error) ->
      _logger.error error
      this.close()
      options.error.call()
      
      # Transmit offline event
      _this.callbacks.offline.call()

    @socket.on 'message', (buffer, info) ->
      _logger.debug 'Packet received from '+ info.address + ':' + info.port + ' with ' + info.size + ' bytes.'
      _response = buffer
      this.close()

      _this.setResponse(_response)
      options.ok.call()

    # Close socket connection if we don't get a reply after certain amount of time
    setTimeout (->
      if _response == null
        _logger.error 'Request timed out after ' + _settings.timeout + ' ms for '+ _this.host + ':' + _this.port + '.'
        _socket.close()
        options.error.call()

        # Transmit offline event
        _this.callbacks.offline.call()
    ), _settings.timeout

  getSocket: ->
    @socket

  getResponse: ->
    @response

  setResponse: (@response) ->

  trackConnection: (callback) ->
    @callbacks.offline = callback

  on: (msg, callback) ->
    _this = this

    switch msg
      when 'offline'
        this.trackConnection (message) ->
            callback(message)

module.exports = Protocol