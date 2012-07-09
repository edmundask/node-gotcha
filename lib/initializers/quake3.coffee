log4js    = require 'log4js'
logger    = log4js.getLogger('[Gotcha]')
parse     = require('arg').parse
Server    = require '../protocols/quake3'

options = parse process.argv.join(' ')
server = new Server options.host, options.port
logger = log4js.getLogger '[Quake3 Protocol]'

logger.setLevel 'ERROR' if !options.verbose

log4js.configure
  appenders: [
    type: 'console'
  ,
    type: 'file',
    filename: './logs/events.log',
    category: '[Quake3 Protocol]'
  ]

process.on 'message', (data) ->
  if data.command = 'pull'
    message = {}

    server.on 'info', (info) ->
      message.meta = 'info'
      message.content = info

      process.send message