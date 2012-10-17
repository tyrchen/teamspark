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
#ts.sparks.total = (projectId) -> Sparks.find(projects: projectId).count()
#ts.sparks.totalFinished = (projectId) -> Sparks.find(projects: projectId, finished: true).count()

ts.sparks.totalUnfinished = (projectId=null, ownerId=null) ->
  ts.sparks.unfinishedItems(projectId, ownerId).count()

ts.sparks.unfinishedItems = (projectId=null, ownerId=null) ->
  query = finished: false
  if projectId
    query.push projects: projectId

  if ownerId
    query.push currentOwnerId: ownerId

  Sparks.find query

ts.sparks.importantItems = (projectId=null, ownerId=null) ->
  query =
    finished: false
    priority: $gt: ts.consts.prio.HIGH

  if projectId
    query.push projects: projectId

  if ownerId
    query.push currentOwnerId: ownerId

  Sparks.find query

ts.sparks.totalImportant = (projectId=null, ownerId=null) ->
  ts.sparks.importantItems(projectId, ownerId).count()

ts.sparks.urgentItems = (projectId=null, ownerId=null) ->
  # tasks expire in 3 days
  time = ts.now() + 3 * 24 * 3600 * 1000
  query =
    deadline: $and: $ne: null, $lt:  time

  if projectId
    query.push projects: projectId

  if ownerId
    query.push currentOwnerId: ownerId

  Sparks.find query

ts.sparks.totalUrgent = (projectId) -> ts.sparks.urgentItems(projectId).count()