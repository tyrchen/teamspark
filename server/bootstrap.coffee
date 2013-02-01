# if database is empty, on startup, create some basic data

resetData = ->
  if Accounts.loginServiceConfiguration.find(service:'weibo').count() is 0
    Accounts.loginServiceConfiguration.insert weibo_service

  if Accounts.loginServiceConfiguration.find(service:'github').count() is 0
    Accounts.loginServiceConfiguration.insert github_service

createUserHook = ->
  Accounts.onCreateUser (options, user) ->
    #console.log 'user:', user

    user.teamId = null
    user.points = 0

    weibo = user.services.weibo
    if weibo?
      token = weibo.accessToken
      weibo_id = weibo.id
      #console.log token
      result = Meteor.http.get(
        "https://api.weibo.com/2/users/show.json",
        {params: {access_token: token, uid: weibo_id}})

      if result.error
        throw result.error
      user.profile = result.data
      user.username = user.profile.screen_name
      user.description = user.profile.description
      user.avatar = user.profile.profile_image_url
      user.url = "http://weibo.com/#{user.profile.profile_url}"
      user.location = user.profile.location
      user.profile.status = null

    github = user.services.github
    if github?
      token = github.accessToken
      result = Meteor.http.get(
        "https://api.github.com/user",
        {params: {access_token: token}})
      if result.error
        throw result.error
      user.profile = result.data
      user.username = user.profile.name
      user.description = user.profile.bio
      user.avatar = user.profile.avatar_url
      user.url = user.profile.html_url
      user.location = user.profile.location
#
#    if user.services.google?
#      user.username = user.profile.name
#      user.description = ''
#      user.avatar = ''
#      user.url = user.profile.link
#      user.location = ''

    return user

Meteor.startup ->
  resetData()
  createUserHook()