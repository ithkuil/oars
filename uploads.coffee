#!/usr/bin/env node
#
# jQuery File Upload Plugin Node.js Example 2.0
# https://github.com/blueimp/jQuery-File-Upload
#
# Copyright 2012, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT


#jslint nomen: true, regexp: true, unparam: true, stupid: true 
#global require, __dirname, unescape, console 

# (modified and converted to coffeescript by Jason Livesay
# because I want to use SSL and can't do cross-origin with SSL
# so this needs to be integrated into the main server)
require('source-map-support').install()
path = require 'path'
fs = require 'fs'
_existsSync = fs.existsSync || path.existsSync

formidable = require 'formidable'
nodeStatic = require 'node-static'
imageMagick = require 'imagemagick'

options =
  tmpDir: __dirname + '/tmp'
  publicDir: __dirname + '/public'
  uploadDir: __dirname + '/public/files'
  uploadUrl: '/files/'
  maxPostSize: 11000000000 # 11 GB
  minFileSize: 0
  maxFileSize: 10000000000 # 10 GB
  acceptFileTypes: /.+/i
  safeFileTypes: /\.(gif|jpe?g|png)$/i
  imageTypes: /\.(gif|jpe?g|png)$/i
  imageVersions: 
    thumbnail: 
      width: 80
      height: 80
  accessControl:
    allowOrigin: '*'
    allowMethods: 'OPTIONS, HEAD, GET, POST, PUT, DELETE'
    allowHeaders: 'X-Requested-With'
  ssl:
    key: fs.readFileSync 'key.pem'
    cert: fs.readFileSync 'cert.pem'


utf8encode = (str) -> unescape encodeURIComponent(str)

nameCountRegexp = /(?:(?: \(([\d]+)\))?(\.[^.]+))?$/

nameCountFunc = (s, index, ext) ->
    ' (' + ((parseInt(index, 10) || 0) + 1) + ')' + (ext || '')

serve = (req, res) ->
  #res.setHeader 'Access-Control-Allow-Origin', options.accessControl.allowOrigin
  #res.setHeader 'Access-Control-Allow-Methods', options.accessControl.allowMethods
  
  handleResult = (result, redirect) ->
    if redirect
      res.writeHead 302, { Location: redirect.replace /%s/,
                          encodeURIComponent(JSON.stringify(result)) }
      res.end()
    else
      res.writeHead 200, { 'Content-Type': 
                            req.headers.accept.indexOf('application/json') != -1 ?
                            'application/json' : 'text/plain' }
                         
      res.end JSON.stringify(result)

  setNoCacheHeaders = ->
    res.setHeader 'Pragma', 'no-cache'
    res.setHeader 'Cache-Control', 'no-store, no-cache, must-revalidate'
    res.setHeader 'Content-Disposition', 'inline; filename="files.json"'

  handler = new UploadHandler req, res, handleResult
  console.log 'req.method is '
  console.log req.method
  switch req.method
    when 'OPTIONS' then res.end()
    when 'HEAD', 'GET'
      if req.url is '/'
        setNoCacheHeaders()
        if req.method is 'GET'
          handler.get()
        else
          res.end()
      else
        console.log 'get request for file??'
        #console.log req?.path
        #fileServer.serve req, res
    when 'POST'
      setNoCacheHeaders()
      handler.post()
    when 'DELETE' then handler.destroy()
    else
      res.statusCode = 405
      res.end()

class FileInfo 
  constructor: (file) ->
    @name = file.name
    @size = file.size
    @type = file.type
    @delete_type = 'DELETE'

  validate: =>
    if options.minFileSize? and options.minFileSize > @size
      @error = 'File is too small'
    else if options.maxFileSize? and options.maxFileSize < @size
      @error = 'File is too big'
    else if not options.acceptFileTypes.test(@name)
      @error = 'Filetype not allowed'
    not @error

  safeName: =>
    console.log 'X'
    #Prevent directory traversal and creating hidden system files:
    @name = path.basename(this.name).replace /^\.+/, ''
    console.log 'X1'
    #Prevent overwriting existing files:
    while _existsSync(options.uploadDir + '/' + @name)
        @name = @name.replace nameCountRegexp, nameCountFunc

  initUrls: (req) =>
    if not @error?
      console.log 'req.headers.host is ' + req.headers.host
      baseUrl = 'https://' + req.headers.host + options.uploadUrl
      console.log 'baseurl is ' + baseUrl
      @url = @delete_url = baseUrl + encodeURIComponent(@name)
      
      for version, val of options.imageVersions
        if _existsSync "#{options.uploadDir}/#{version}/#{@name}"
          @[version + '_url'] = baseUrl + version + '/' + encodeURIComponent(@name)


class UploadHandler 
  constructor: (@req, @res, @callback) ->

  get: =>
    files = [];

    fs.readdir options.uploadDir, (err, list) =>
      for name in list
        stats = fs.statSync options.uploadDir + '/' + name
        if stats.isFile()
          fileInfo = new FileInfo { name: name, size: stats.size }
          fileInfo.initUrls @req
          files.push fileInfo

      @callback { files: files }

  post: =>
    #var handler = this
    form = new formidable.IncomingForm()
    tmpFiles = []
    files = []
    map = {}
    counter = 1
    redirect = null

    finish = =>
      counter -= 1
      if !counter
        for fileInfo in files
          fileInfo.initUrls @req
        @callback { files: files }, redirect

    form.uploadDir = options.tmpDir

    form.on 'fileBegin', (name, file) =>
      if not file?
        console.log "Problem: no file!"
        console.log name
      tmpFiles.push file.path
      fileInfo = new FileInfo file, @req, true
      fileInfo.safeName()
      map[path.basename(file.path)] = fileInfo
      files.push fileInfo

    form.on 'field', (name, value) =>
      if name is 'redirect' then redirect = value
      
    form.on 'file', (name, file) =>
      if not file?
        console.log "Problem: no file!"
        console.log name
      fileInfo = map[path.basename(file.path)]
      fileInfo.size = file.size;
      if not fileInfo.validate()
        fs.unlink file.path
        return

      fs.renameSync file.path, options.uploadDir + '/' + fileInfo.name

      if options.imageTypes.test(fileInfo.name)
        for version, val of options.imageVersions         
          counter += 1
          opts = options.imageVersions[version]
          imageMagick.resize {
            width: opts.width
            height: opts.height
            srcPath: "#{options.uploadDir}/#{fileInfo.name}"
            dstPath: "#{options.uploadDir}/#{version}/#{fileInfo.name}"
            }, finish

    form.on 'aborted', =>
      for file in tmpFiles
        fs.unlink file
        
    form.on 'error', (e) ->
      console.log e

    form.on 'progress', (bytesReceived, bytesExpected) =>
      if bytesReceived > options.maxPostSize
        @req.connection.destroy()
        
    form.on('end', finish).parse @req

  destroy: =>
    fileName = null

    if @req.url.slice(0, options.uploadUrl.length) is options.uploadUrl
      fileName = path.basename decodeURIComponent(@req.url)

      fs.unlink "#{options.uploadDir}/#{fileName}", (ex) =>
        for version, val of options.imageVersions
          fs.unlink "#{options.uploadDir}/#{version}/#{fileName}/"
          
        @callback { success: not ex? }
      
    else
      @callback { success: false }

exports.serve = serve