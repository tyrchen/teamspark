ts = ts || {}

ts.now = ->
  (new Date()).getTime()

ts.currentTeam = ->
  Teams.findOne _id: Meteor.user().teamId

ts.isStaff = (team) -> team and Meteor.user()._id is team.authorId
ts.isFreelancer = (user) -> not user.teamId



# model functions
ts.sparks = ts.sparks || {}

ts.sparks.total = (projectId) -> Sparks.find(projectId: projectId).count()

ts.sparks.totalUnfinished = (projectId) -> ts.sparks.unfinishedItems().count()

ts.sparks.totalFinished = (projectId) -> Sparks.find(projectId: projectId, finished: true).count()

ts.sparks.unfinishedItems = (projectId=null) ->
  if projectId
    Sparks.find projectId: projectId, finished: false
  else
    Sparks.find finished: false

ts.sparks.importantItems = (projectId) -> Sparks.find projectId: projectId, priority: $gt: ts.consts.prio.HIGH

ts.sparks.totalImportant = (projectId) -> ts.sparks.importantItems().count()

ts.sparks.urgentItems = (projectId) ->
  # tasks expire in 3 days
  time = ts.now() + 3 * 24 * 3600 * 1000
  Sparks.find $and: [projectId: projectId, deadline: $ne: null, deadline: $lt:  time]

ts.sparks.totalUrgent = (projectId) -> ts.sparks.urgentItems().count()