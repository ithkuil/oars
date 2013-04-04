express = require 'express'
fs = require 'fs'
Mongolian = require 'mongolian'
server = new Mongolian
db = server.db 'scriptdb'
feedParser = require 'feedparser'
dateFormat = require 'dateformat'

delay = (ms, func) -> setTimeout func, ms
interval = (ms, func) -> setInterval func, ms

express = require 'express'
app = express()

app.use express.static('public')

html = fs.readFileSync 'index.html', 'utf8'

app.get '/', (req, res) ->
  res.redirect '/dash'

app.get "/feed/:url", (req, res) ->
  feedParser.parseUrl req.params.url, (err, meta, articles) ->
    if err?
      console.log "Problem reading feed"
      console.log err
      res.end JSON.stringify({title: 'error'})
    else
      res.end JSON.stringify(articles)

app.get "/upcoming", (req, res) ->
  events = db.collection 'events'
  events.find().toArray (e, arr) ->
    for ev in arr
      ev.date = dateFormat ev.date, 'fullDate'
    res.end JSON.stringify(arr)

app.get '*', (req, res, next) ->
  console.log req.path
  res.end html

process.on 'uncaughtException', (err) ->
  console.log 'Uncaught exception:'
  console.log err
  console.log err.stack

app.listen 3002
