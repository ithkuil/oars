passwordHash = require 'password-hash'
randpass = require 'randpass'
fs = require 'fs'
nodemailer = require 'nodemailer'

smtp = nodemailer.createTransport "SMTP",
  service: "Gmail"
  auth:
    user: "ckgsolutions1@gmail.com"
    pass: "x85a3h9w"

users = {}


save = =>
  console.log 'x1'
  fs.writeFileSync __dirname + '/userdata.json', JSON.stringify(users), 'utf8'
  console.log 'x2'


console.log '1'
if not fs.existsSync(__dirname + '/userdata.json')  
  console.log '2'
  users.admin = 
    email: ""
    name: "admin"
    realname: "Administrator"
    passhash: passwordHash.generate('admin')
    permissions:
      opportunities: "readwrite"

  console.log '3'
  save()  
  console.log '4'

users = JSON.parse(fs.readFileSync __dirname + '/userdata.json', 'utf8')

addNoEmail = (data) ->
  users[data.name] = data
  users[data.name].passhash = passwordHash.generate data.pass
  delete users[data.name].pass
  save()

add = (email, name) =>
  if not users[name]?
    pass = randpass()
    users[name] = { email, name, passhash: passwordHash.generate pass }

    try
      options =
        from: 'oars <root@oarsmanagement.com>'
        to: email
        subject: 'OARS User account created'
        text: "Username: " + name + " password: " + pass
      smtp.sendMail options, (err, res) ->
        if err?
          console.log err
        else
          console.log 'Message sent: ' + res.message
    catch e
      console.log 'Error sending user mail' + e.message
      console.log e

    save()

resetPassword = (name) =>
  if users[name]?
    pass = randpass()
    users[name].passhash = passwordHash.generate pass

    try
      options =
        from: 'oars <root@oarsmanagement.com>'
        to: users[name].email
        subject: 'OARS user password reset'
        text: "Username: " + name + " password: " + pass
      smtp.sendMail options, (err, res) ->
        if err?
          console.log err
        else
          console.log 'Message sent: ' + res.message
    catch e
      console.log 'Error sending user mail' + e.message
      console.log e

    save()


updatePassword = (username, oldpass, newpass) =>
  if not checkPassword(username, oldpass)
    return false
  else
    users[username].passhash = passwordHash.generate newpass
    save()
    return true

checkPassword = (username, pass) =>
  console.log 'users is'
  console.log users
  user = users[username]
  console.log user
  if user?
    return passwordHash.verify pass, user.passhash
  else
    return false

getUsers = =>
  ret = []
  console.log 'inside of getUsers'
  console.log users
  for userkey, user of users
    console.log user
    ret.push nopassUser user
  console.log 'getusers returning'
  console.log ret
  ret

nopassUser = (user) =>
  mod = {}
  for key, val of user
    if not (key is 'passhash')
      mod[key] = val
  mod

find = (name) =>  
  nopassUser users[name]

update = (data, cb) =>
  users[data.name] = data
  users[data.name].passhash = passwordHash.generate data.pass  
  delete users[data.name].pass
  save()
  cb?()

sendMail = (data, cb) ->
  options =
    from: 'oars <root@oarsmanagement.com>'
    to: data.to
    subject: data.subject
    text: data.text
    html: data.html
  smtp.sendMail options, (err, res) ->
    if err?
      console.log err
      cb err
    else
      console.log 'Message sent: ' + res.message  
      cb null, true


exports.add = add
exports.resetPassword = resetPassword
exports.updatePassword = updatePassword
exports.checkPassword = checkPassword
exports.save = save
exports.addNoEmail = addNoEmail
exports.users = users
exports.getUsers = getUsers
exports.update = update
exports.find = find
exports.sendMail = sendMail

