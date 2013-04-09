express = require 'express'
fs = require 'fs'
Mongolian = require 'mongolian'
server = new Mongolian
db = server.db 'scriptdb'
feedParser = require 'feedparser'
dateFormat = require 'dateformat'

ObjectId = Mongolian.ObjectId
ObjectId.prototype.toJSON = ->
  return @toString()

convertids = (obj) ->
  if obj['_id']?
    obj['_id'] = new ObjectId(obj['_id'])

  if obj['id']?
    obj['_id'] = new ObjectId(obj['id'])
    delete obj['id']

feeds = {}

delay = (ms, func) -> setTimeout func, ms
interval = (ms, func) -> setInterval func, ms

express = require 'express'
app = express()

app.use express.static('public')
app.use express.bodyParser()
app.use express.methodOverride()


html = fs.readFileSync 'index.html', 'utf8'

events = db.collection 'events'

app.get '/data/events/:id', (req, res) ->
  convertids req.params
  events.findOne {_id: req.params._id}, (err, ev) ->
    ev.date = new Date(ev.date)
    res.end JSON.stringify(ev)
    #events.update { _id: req.params.id}, data,

app.delete '/data/events/:id', (req, res) ->
  ids = { _id: req.params.id }
  convertids ids
  events.remove ids, (err, ev) ->
    res.end '1'

app.put '/data/events/:id', (req, res) ->
  console.log '-- put event'
  ids = { _id : req.params.id }
  convertids ids
  events.update ids, req.body, (err) ->
    res.end('1')


app.post '/data/events', (req, res) ->
  console.log '-- post event'
  console.log req.body
  console.log req.path
  events.insert req.body
  res.end('1')


getFeed = (url, cb) ->
  feedParser.parseUrl url, (err, meta, articles) ->
    if not err?
      feeds[url] = articles
    cb? feeds[url]

app.get "/feed/:url", (req, res) ->
  if feeds[req.params.url]?
    res.end JSON.stringify(feeds[req.params.url])
  else
    getFeed req.params.url, (articles) ->
      res.end JSON.stringify(articles)
      interval 1000 * 60 * 1, ->
        getFeed req.params.url


app.get "/upcoming", (req, res) ->
  events.find().toArray (e, arr) ->
    for ev in arr
      ev.date = dateFormat ev.date, 'shortDate'
    res.end JSON.stringify(arr)

app.get '*', (req, res, next) ->
  console.log req.path
  res.end html

process.on 'uncaughtException', (err) ->
  console.log 'Uncaught exception:'
  console.log err
  console.log err.stack

app.listen 8090
