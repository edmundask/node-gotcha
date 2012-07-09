_         = require 'underscore'
fork      = require('child_process').fork
parse     = require('arg').parse
log4js    = require 'log4js'
logger    = log4js.getLogger '[Gotcha]'
socket    = require 'socket.io'

config    = require '../../config'
options  = parse config.default_args

io = null

# Get the arguments that were passed through the command line
passed_args = parse process.argv.join ' '

# Add options from the command line
_.each _.keys(passed_args), (key) ->
  options[key] = passed_args[key]

# These arguments will be sent to each child process (worker)
if options.verbose || options.v
  args += ' -verbose'

run = ->
  io = socket.listen config.listen_port
  io.set 'log level', 1

  message = 
    command: 'pull'

  logger.info 'Initializing workers...'
  servers = require '../../servers'

  for server in servers
    server.host = config.default_host if !server.host
    server.timeout = config.default_timeout if !server.timeout
    name = '"'+ server.name + '" ('+ server.host + ':' + server.port + ')'

    logger.info 'Initializing worker for ' + name

    switch server.game
      when 'ro2'
        if options.ro2 || options.all
          worker = fork 'lib/workers/ro2.js', ['-host ' + server.host + ' -port ' + server.port]
          work(worker, server, message)
      when 'fear'
        if options.fear || options.all
          worker = fork 'lib/workers/fear.js', ['-host ' + server.host + ' -port ' + server.port]
          work(worker, server, message)
      when 'cod4'
        if options.cod4 || options.all
          worker = fork 'lib/workers/cod4.js', ['-host ' + server.host + ' -port ' + server.port]
          work(worker, server, message)
      when 'mumble'
        if options.mumble || options.all
          worker = fork 'lib/workers/mumble.js', ['-host ' + server.host + ' -port ' + server.port]
          work(worker, server, message)
      else
        logger.warn 'No protocol handler was found for ' + server.name

# Show servers list
servers_list = ->
  servers = require '../../servers'

  logger.info 'Displaying servers list...'

  for server in servers
    server.host = config.default_host if !server.host

    console.log server.name + ' | ' + server.host + ':' + server.port + ' | ' + 'Game: ' + server.game

# Show help
show_help = ->
  console.log ''
  console.log '-servers                             Show servers list'
  console.log '-run [-gametype1] [-gametype2] ...   Run the listener'
  console.log ''

  console.log 'Copyright (c) Edmundas Kondrašovas 2012'
  console.log '---------------------------------------'
  console.log ''

# Internal function to periodically get updates from the server
work = (worker, server, message) ->
  name = '"'+ server.name + '" ('+ server.host + ':' + server.port + ')'

  publicData = 
    server: server

  worker.on 'message', (data) ->
    publicData.data = data

    switch data.meta
      when 'players'
        logger.info 'Received players list for ' + name
        publicData.name = 'players'
      when 'info'
        publicData.name = 'info'
        logger.info 'Received INFO for ' + name

    io.sockets.emit 'server', publicData

  setInterval (->
    worker.send message
  ), config.update_interval

  config.update_interval += config.worker_distance

# React to command line arguments
if options.run
  run()

if options.servers
  servers_list()

if options.h || options.help
  show_help()

module.exports.run = run
module.exports.servers = servers_list