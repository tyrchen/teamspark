# if database is empty, on startup, create some basic data

resetData = ->
  user = Meteor.users.findOne username: '陈天_Tyr'
  if Teams.find().count() is 0 and user?
    # team = { _id: uuid, name: '途客圈战队', authorId: userId, members: [userId, userId, ... ]}
    data = [
      {name: '途客圈战队', authorId: user._id, members: [user._id]}
    ]

    for item in data
      Teams.insert
        name: item.name
        authorId: item.authorId
        members: item.members
        createdAt: ns.getNow()

createUserHook = ->
  Accounts.onCreateUser (options, extra, user) ->
    user.services = options.services
    user.profile = extra.profile
    user.teamId = null

    if user.services.weibo?
      user.username = user.profile.screen_name
      user.avatar = user.profile.profile_image_url
      user.url = "http://weibo.com/#{user.profile.profile_url}"
      user.location = user.profile.location
      user.profile.status = null

    if user.services.github?
      user.username = user.profile.name
      user.avatar = user.profile.avatar_url
      user.url = user.profile.html_url
      user.location = user.profile.location

    return user

Meteor.startup ->
  resetData()
  createUserHook()