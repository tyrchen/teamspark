# team = { _id: uuid, name: '途客圈战队', authorId: userId, members: [userId1, userId2, ... ], createdAt: Date(), abbr: 'tkq', nextIssueId: 0}
Teams = new Meteor.Collection 'teams'

# profile = {
#   _id: uuid, userId: userId, online: true/false, teamId: teamId,
#   lastActive: new Date(), totalSeconds: integer
#   totalSubmitted: 0, totalUnfinished: 0, totalFinished: 0
# }
Profiles = new Meteor.Collection 'profiles'

# project = {
#   _id: uuid, name: 'cayman', description: 'cayman is a project', authorId: null,
#   parent: null, teamId: teamId, createdAt: Date()
#   unfinished: 0, finished: 0, verified: 0
# }
Projects = new Meteor.Collection 'projects'

# spark = {
# _id: uuid, type: 'idea', authorId: userId, auditTrails: [],
# owners: [userId, ...], finishers: [userId, ...], verified: false, progress: 10,
# title: 'blabla', content: 'blabla', priority: 1, supporters: [userId1, userId2, ...],
# finished: false, projects: [projectId, ...], deadline: Date(), createdAt: Date(),
# updatedAt: Date(), finishedAt: Date(), positionedAt: Date(), teamId: teamId, points: 16, totalPoints: 64
# tags: [], issueId: 'tkq1'
# }
Sparks = new Meteor.Collection 'sparks'

# auditTrail = { _id: uuid, userId: userId, content: 'bla bla', teamId: teamId, projectId: projectId, sparkId: sparkId, createdAt: Date()}
AuditTrails = new Meteor.Collection 'auditTrails'

# notification = {
# _id: uuid, recipientId: userId, level: 1-5|debug|info|warning|important|urgent
# type: 1-5 | user | spark | project | team | site
# title: 'bla', content: 'html bla', url: 'url', createdAt: new Date(), readAt: new Date(), visitedAt: new Date() }
Notifications = new Meteor.Collection 'notifications'

# dayStat = {
#   _id: uuid, date: new Date(), teamId: teamId,
#   positioned: { total: 1], userId2: [0, 0,0,0,0,0], ... } # index 0 is total[15, 1,2,3,4,5], userId1: [3, 1, 0, 0, 1,
#   finished: { the same as created}
# }
DayStats = new Meteor.Collection 'dayStats'

# weekStat = {
#   _id: uuid, date: new Date(), teamId: teamId, projectId: projectId,
#   positioned: { total: 1], userId2: [0, 0,0,0,0,0], ... } # index 0 is total[15, 1,2,3,4,5], userId1: [3, 1, 0, 0, 1,
#   finished: { the same as create }
#   burned: [79, 56, 40, 32, 24, 12, 3]
# }
WeekStats = new Meteor.Collection 'weekStats'

# tag = { _id: uuid, name: '剪辑器', teamId: teamId, projectId: projectId, sparks: 0, createdAt: new Date()}
Tags = new Meteor.Collection 'tags'