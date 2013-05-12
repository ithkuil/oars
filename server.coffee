express = require 'express'
MemoryStore = express.session.MemoryStore
prettyjson = require 'prettyjson'

fs = require 'fs'
Mongolian = require 'mongolian'
server = new Mongolian
db = server.db 'scriptdb'
feedParser = require 'feedparser'
dateFormat = require 'dateformat'
auth = require './auth'

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
app.use express.cookieParser()

sessionopts = 
  store: new MemoryStore()
  secret: 'secret'
  key: 'bla'

app.use express.session(sessionopts)


html = fs.readFileSync 'index.html', 'utf8'

events = db.collection 'events'

app.get '/data/events/:id', (req, res) ->
  convertids req.params
  events.findOne { _id: req.params._id }, (err, ev) ->
    ev.date = new Date(ev.date)
    res.end JSON.stringify(ev)

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
  events.insert req.body
  res.end('1')


#--users
users = db.collection 'users'

opportunity = db.collection 'opportunity'

app.get '/data/users/:name', (req, res) ->
  user = auth.find req.params.name
  console.log 'name is ' + req.params.name
  console.log 'user at name is'
  console.log user
  res.end JSON.stringify(user)

app.delete '/data/users/:id', (req, res) ->
  ids = { _id: req.params.id }
  convertids ids
  #events.remove ids, (err, ev) ->
  #  res.end '1'

app.put '/data/users/:id', (req, res) ->
  console.log 'put user'
  console.log req
  data = 
    name: req.body.name
    email: req.body.email
    pass: req.body.password
    realname: req.body.realname
    permissions: req.body.permissions  
  auth.update data, (err) ->
    res.end('1')

app.post '/data/users', (req, res) ->
  console.log 'user posted'
  data = 
    name: req.body.name
    email: req.body.email
    pass: req.body.password
    realname: req.body.realname
    permissions: req.body.permissions
  auth.addNoEmail data
  res.end('1')

app.get '/data/users', (req, res) ->
  console.log 'get users list'
  console.log auth.getUsers()
  res.end JSON.stringify(auth.getUsers())

#-- /users

app.get '/sessiondata', (req, res) ->
  console.log req.session
  user = auth.find req.session.user
  console.log 'sessiondata returning'
  console.log user
  res.end JSON.stringify(user)

projects = db.collection 'projects'

app.get '/data/sources', (req, res) ->
  projects.distinct 'source', (err, arr) ->
    ret = []
    for source in arr
      ret.push { name: source }
    res.end JSON.stringify(ret)

app.get '/data/statuses', (req, res) ->
  projects.distinct('status').toArray (e, arr) ->
    res.end JSON.stringify(arr)

app.get '/data/genres', (req, res) ->
  projects.distinct('genre').toArray (e, arr) ->
    res.end JSON.stringify(arr)


#-- opportunity

app.get '/data/opportunity', (req, res) ->
  if req.query.filter?
    filter = JSON.parse req.query.filter
    opportunity.find(filter).toArray (e, arr) ->
      res.end JSON.stringify(arr)
  else
    opportunity.find().toArray (e, arr) ->
      res.end JSON.stringify(arr)

app.get '/data/opportunity/:id', (req, res) ->
  convertids req.params
  opportunity.findOne {_id: req.params._id}, (err, ev) ->
    res.end JSON.stringify(ev)

app.delete '/data/opportunity/:id', (req, res) ->
  ids = { _id: req.params.id }
  convertids ids
  opportunity.remove ids, (err, ev) ->
    res.end '1'

app.put '/data/opportunity/:id', (req, res) ->
  console.log '-- put opp'
  ids = { _id : req.params.id }
  convertids ids
  opportunity.update ids, req.body, (err) ->
    res.end('1')

app.post '/data/opportunity', (req, res) ->
  opportunity.insert req.body
  res.end('1')

#/opportunity

app.get '/data/projects', (req, res) ->
  if req.query.filter?
    filter = JSON.parse req.query.filter
    projects.find(filter).toArray (e, arr) ->
      res.end JSON.stringify(arr)
  else
    projects.find().toArray (e, arr) ->
      res.end JSON.stringify(arr)

app.get '/data/projects/:id', (req, res) ->
  convertids req.params
  projects.findOne {_id: req.params._id}, (err, ev) ->
    ev.date = new Date(ev.date)
    res.end JSON.stringify(ev)

app.delete '/data/projects/:id', (req, res) ->
  ids = { _id: req.params.id }
  convertids ids
  projects.remove ids, (err, ev) ->
    res.end '1'

app.put '/data/projects/:id', (req, res) ->
  console.log '-- put project'
  ids = { _id : req.params.id }
  convertids ids
  projects.update ids, req.body, (err) ->
    res.end('1')

app.post '/data/projects', (req, res) ->
  console.log 'post = insert project'
  projects.insert req.body
  res.end('1')

app.post '/data/reviews/add/:projectid', (req, res) ->
  console.log 'add review'
  ids = { _id : req.params.projectid }
  convertids ids
  projects.findOne ids, (err, project) ->
    if err?
      console.log err
      res.end err.message
    else
      console.log project
      if not project.reviews?
        project.review = []
      project.reviews.push req.body
    projects.update ids, project
    res.end '1'

convertAnsi = (text) ->
  Convert = require 'ansi-to-html'
  convert = new Convert()
  text = text.replace /\n/g, '<br/>'
  htmlx = convert.toHtml text
  htmlx = '<div style="padding: 20px; background: #111;"">' + htmlx + '</div>'
  htmlx

app.post '/sendreview/:email', (req, res) ->
  console.log 'Send review'
  ansi = prettyjson.render req.body
  console.log ansi
  html = convertAnsi ansi

  opts =
    to: req.params.email
    subject: 'review'
    text: html
    html: html
  auth.sendMail opts, (err, success) ->
    if err?      
      res.end 'error'
    else
      res.end 'ok'


getFeed = (url, cb) ->
  feedParser.parseUrl url, (err, meta, articles) ->
    if not err?
      filtered = []
      for article in articles
        filtered.push { link: article.link, title: article.title }
      feeds[url] = filtered
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

app.post '/dologin', (req, res) ->
  console.log 'do login'
  if not auth.checkPassword(req.body.user, req.body.password)
    res.end "Bad login.  Go back to try again."
  else
    req.session.user = req.body.user
    console.log 'redirecting'
    res.redirect '/'

app.get '/logout', (req, res) ->
  console.log 'LOGOUT'
  req.session.user = ''
  console.log 'redirecting 1'
  res.redirect '/login.html'

app.post '/forgot', (req, res) ->
  auth.resetPassword req.body.user
  res.end """
    <html>
    <head><title></title></head><body>
    Password reset and sent to email address.  
    Redirecting to login page...
    <script>setTimeout(function() { window.location.href="/login.html"; }, 2000);
    </script>
    </body></html>
  """

app.get '*', (req, res, next) ->  
  console.log req.path
  if not req.session?.user?
    res.redirect '/login.html'
  else
    res.end html

process.on 'uncaughtException', (err) ->
  console.log 'Uncaught exception:'
  console.log err
  console.log err.stack

console.log "Port 8090"
app.listen 8090
