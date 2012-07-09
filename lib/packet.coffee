prettyBuffer = require('./prettyBuffer').prettyBuffer
jspack  = require 'jspack'
bufferpack = require 'bufferpack'

class Packet
  constructor: (buffer) ->
    @originalBuffer = buffer
    @buffer = new Buffer(buffer.length)
    @originalBuffer.copy(@buffer)
    @position = 0

  skip: (size) ->
    @position += size

  read: (bytes) ->
    buff = []

    for p in [0...bytes]
      buff.push @buffer[@position+p]
    this.skip(bytes)

    buff

  getByte: ->
    this.skip(1)
    @buffer[@position - 1]

  getByteStr: ->
    this.getByte().toString 16

  getInt: ->
    this.skip(4)
    @buffer.readInt32LE(@position - 4)

  getLong: ->
    this.skip(4)
    @buffer.readInt32LE(@position - 4)

  # we apply a simple workaround for Javascript's lack of longint support
  getLongFixed: ->
    number = this.getLong().toString(10)
    number = parseInt(number, 10)

  getShort: ->
    this.skip(2)
    @buffer.readInt16LE(@position - 2)

  getFloat: ->
    res = bufferpack.unpack('<f', @buffer, @position)
    @position += 4
    res

  getString: (delimiter = 0) ->
    byte = @buffer[@position]
    str = ''

    while byte != delimiter
      str += String.fromCharCode(byte)
      @position++
      byte = @buffer[@position]

    if byte == delimiter
      @position++

    str

  pos: (position) ->
    @position = position if position >= 0

  getPos: ->
    @position

  buffer: ->
    @buffer[@position]

  hex2a: (hex) ->
    i = 0
    str = ''

    while i < hex.length
      str += String.fromCharCode(parseInt(hex.substr(i, 2), 16))
      i += 2
    str

  toString: ->
    prettyBuffer(@buffer, @position, @buffer.length - @position)

module.exports = Packet