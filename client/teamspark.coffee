ts = ts || {}
ts.filteringTeam = ->
  ts.State.filterType.get() is 'team'

ts.filteringUser = ->
  ts.State.filterType.get() is 'user'

ts.filteringProject = ->
  ts.State.filterSelected.get() isnt 'all'

_.extend Template.content,
  loggedIn: -> Meteor.userId
  teamActivity: -> ts.State.activityDisplay.get() is 'team'
  projects: -> Projects.find()
  teamName: -> ts.currentTeam()?.name


_.extend Template.member,
  projects: -> Projects.find()
  totalUnfinished: (projectId) ->
    ts.sparks.totalUnfinished projectId, @_id
