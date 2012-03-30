
ll = console.log
my_email = 'jiyinyiyong@qq.com'

fs = require 'fs'
# check_assertion = require 'browserid-verifier'
check_assertion = (v...) -> ll 'rrr'
crypto = require('ezcrypto').Crypto

handler = (req, res) ->
  html_file = fs.readFileSync 'page.html', 'utf-8'
  coffee_file = fs.readFileSync 'client.coffee', 'utf-8'
  html = html_file.replace '@@@', coffee_file
  res.writeHead 200, 'content-Type': 'text/html'
  res.end html

port = process.env.PORT || 8000
app = (require 'http').createServer handler
app.listen port

time_mark = ->
  time = new Date
  month = do time.getMonth
  date = do time.getDate
  hour = do time.getHours
  min = do time.getMinutes
  "#{month}/#{date}_#{hour}:#{min}"

index = ->
  do (new Date).getTime

#url = 'mongodb://nodejs:nodejsPasswd@localhost:27017/daily_bookmarks'
url = 'mongodb://nodejs:nodejsPasswd@ds031617.mongolab.com:31617/jiyinyiyong'
(require 'mongodb').connect url, (err, db) ->
  io = (require 'socket.io').listen app
  io.set 'log level', 1

  io.sockets.on 'connection', (socket) ->

    user = {}
    authed = no
    
    sync_user_info = (email) ->
      user.email = email
      user.md5 = crypto.MD5 (new Date).toString()

      db.collection 'user', (err, collection) ->
        collection.update
          email: user.email
          $set: {md5: user.md5}

      socket.emit 'sync_user_info', user
      authed = yes

    new_bookmarks = ->
      db.collection 'bookmarks', (err, collection) ->
        collection.create
        (collection.find {}, {sort: {index: -1}, limit: 20}).toArray (err, bookmarks) ->
          socket.emit 'new_bookmarks', bookmarks

    do new_bookmarks
    socket.on 'new_bookmarks', ->
      do new_bookmarks

    socket.on 'assertion', (assertion) ->
      ll 'calling assertion, will fail...'
      check_assertion
        assertion: assertion
        audience: 'http://localhost:8000'
        (err, result) ->
          throw err if err?
          if result.email is my_email
            sync_user_info my_email
          else socket.emit 'login_err'

    socket.on 'check_local', (local) ->
      ll 'on local...', local
      db.collection 'user', (err, collection) ->
        collection.findOne
          email: my_email, md5: user.md5
          (err, one_json) ->
            ll one_json
            if one_json?
              sync_user_info my_email
            else socket.emit 'login_err'

    socket.on 'create_post', (post_data) ->
      if authed
        time = do time_mark
        db.collection 'bookmarks', (err, collection) ->
          collection.save
            time: time, post: post_data, index: (do index)
            (err, state) ->
              ll state
              do new_bookmarks

    all_bookmarks = ->
      db.collection 'bookmarks', (err, collection) ->
        (collection.find {}).toArray (err, bookmarks) ->
          socket.emit 'all_bookmarks', bookmarks

    do new_bookmarks
    socket.on 'all_bookmarks', ->
      do all_bookmarks
