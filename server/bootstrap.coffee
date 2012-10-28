# if database is empty, on startup, create some basic data

resetData = ->
  user = Meteor.users.findOne username: '陈天_Tyr'
  if Profiles.find().count() is 0
    users = Meteor.users.find().fetch()
    _.each users, (user) ->
      Profiles.insert
        userId: user._id
        username: user.username
        online: false
        teamId: user.teamId

  if not user.points
    users = Meteor.users.find().fetch()
    _.each users, (user) ->
      totalCreated = Sparks.find(authorId: user._id).count() * ts.consts.points.CREATE_SPARK
      totalFinished = Sparks.find({owners: user._id, finished: true}).count() * ts.consts.points.FINISH_SPARK
      Meteor.users.update user._id, $set: points: totalCreated + totalFinished

  if Teams.find().count() is 0 and user?
    # team = { _id: uuid, name: '途客圈战队', authorId: userId, members: [userId, userId, ... ]}
    data = [
      {name: '途客圈战队', authorId: user._id, members: [user._id]}
    ]

    for item in data
      id = Teams.insert
        name: item.name
        authorId: item.authorId
        members: item.members
        createdAt: ts.now()

      Meteor.users.update user._id, '$set': 'teamId': id

createUserHook = ->
  Accounts.onCreateUser (options, user) ->
    #console.log 'options:', options, 'user:', user
    user.profile = options.profile
    user.teamId = null

    if user.services.weibo?
      user.username = user.profile.screen_name
      user.description = user.profile.description
      user.avatar = user.profile.profile_image_url
      user.url = "http://weibo.com/#{user.profile.profile_url}"
      user.location = user.profile.location
      user.profile.status = null

    if user.services.github?
      user.username = user.profile.name
      user.description = user.profile.bio
      user.avatar = user.profile.avatar_url
      user.url = user.profile.html_url
      user.location = user.profile.location

    if user.services.google?
      user.username = user.profile.name
      user.description = ''
      user.avatar = ''
      user.url = user.profile.link
      user.location = ''

    return user

Meteor.startup ->
  resetData()
  createUserHook()