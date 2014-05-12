
mongoose = require 'mongoose'
{generate} = require './hash'

config = require '../config'

u = config.dbUser
p = config.dbPass
n = config.dbName
host = "mongodb://#{u}:#{p}@localhost:27017/#{n}"
mongoose.connect host
# mongoose.set 'debug', yes

topicSchema = require('./topic').Schema
userSchema = require('./user').Schema

Topic = mongoose.model 'Topic', topicSchema
User = mongoose.model 'User', userSchema

Topic.on 'index', (err) ->
  console.log err

exports.all = (cb) ->
  Topic.find {}, null, sort: '-time', limit: 20, (err, docs) ->
    console.log err if err?
    cb docs

exports.more = (time, cb) ->
  query =
    time:
      $lt: time
  console.log query
  Topic.find query, null, sort: '-time', limit: 20, (err, docs) ->
    console.log err if err?
    cb docs

exports.del = (id) ->
  Topic.where().findOneAndRemove _id: id, (err, docs) ->
    console.log err if err?
    console.log 'removing', docs, id

exports.save = (data) ->
  topic = new Topic data
  console.log topic, data
  topic.save (err, docs) ->
    console.log err if err?
    console.log docs
    Topic.ensureIndexes (err) ->
      console.log 'index err:', err

exports.change = (id, data, cb) ->
  Topic.update _id: id, data, (err, count) ->
    console.log err if err?
    console.log 'updated count:', count
    cb()

exports.auth = (password, cb) ->
  hash = generate password
  User.where().findOne password: hash, (err, user) ->
    if err? or (not user?)
      console.log err
      cb null
    else
      user.token = generate (new Date).toString()
      user.save()
      cb user

exports.findByToken = (token, cb) ->
  User.where().findOne {token}, (err, user) ->
    if err? or (not user?)
      console.log err
      cb null
    else
      console.log user
      cb user