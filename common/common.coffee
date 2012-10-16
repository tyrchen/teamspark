ts = ts || {}

ts.now = ->
  (new Date()).getTime()

ts.currentTeam = ->
  user = Meteor.user()
  if user
    return Teams.findOne _id: Meteor.user().teamId
  return null


ts.isStaff = (team) -> team and Meteor.user()._id is team.authorId
ts.isFreelancer = (user) -> not user.teamId
ts.isTeamProject = (project, team) -> project.teamId is team._id



# model functions
ts.sparks = ts.sparks || {}
ts.sparks.types = ->
  [
    {name: '点子', id: 'idea', icon: 'icon-magic'},
    {name: 'BUG', id: 'bug', icon: 'icon-exclamation-sign'},
    {name: '需求', id: 'feature', icon: 'icon-money'},
    {name: '任务', id: 'task', icon: 'icon-inbox'},
  ]
ts.sparks.total = (projectId) -> Sparks.find(projects: projectId).count()

ts.sparks.totalUnfinished = (projectId) -> ts.sparks.unfinishedItems(projectId).count()

ts.sparks.totalFinished = (projectId) -> Sparks.find(projects: projectId, finished: true).count()

ts.sparks.unfinishedItems = (projectId=null) ->
  if projectId
    Sparks.find projects: projectId, finished: false
  else
    Sparks.find finished: false

ts.sparks.importantItems = (projectId) -> Sparks.find projects: projectId, priority: $gt: ts.consts.prio.HIGH

ts.sparks.totalImportant = (projectId) -> ts.sparks.importantItems(projectId).count()

ts.sparks.urgentItems = (projectId) ->
  # tasks expire in 3 days
  time = ts.now() + 3 * 24 * 3600 * 1000
  Sparks.find $and: [projects: projectId, deadline: $ne: null, deadline: $lt:  time]

ts.sparks.totalUrgent = (projectId) -> ts.sparks.urgentItems(projectId).count()