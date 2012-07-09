net   = require 'net'
log4js  = require 'log4js'
logger  = log4js.getLogger('[TCP Protocol]')

class TCP
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
      timeout: 400

    # Active TCP socket
    @socket = null

    # Logger instance
    @logger = logger

    # Reply from the server (received packet)
    @response = null

    # Received challenge
    @challenge = null

    # Callbacks
    @callbacks =
      offline: (->)

  sendPacket: (packet, options) ->
    @socket = net.createConnection @port, @host
    @response = ''

    # This is to fix issues with scoping
    [_response, _logger, _socket, _settings, _this] = [@response, @logger, @socket, @settings, this]

    options.ok = options.ok || (->)
    options.error = options.error || (->)

    @socket.setTimeout @settings.timeout

    @socket.on 'connect', ->
      _logger.trace 'Connection established.'
      _logger.trace 'Sending packet...'

      this.write packet

    @socket.on 'data', (data) ->
      _logger.debug 'Data received from '+ _this.host + ':' + _this.port + ' with ' + data.length + ' bytes.'
      _response += data

      _this.setResponse(_response)

    @socket.on 'end', ->
      options.ok.call()

    @socket.on 'error', (error) ->
      _logger.error error
      this.end()
      options.error.call()

      # Transmit offline event
      _this.callbacks.offline.call()

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

module.exports = TCP