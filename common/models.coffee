# team = { _id: uuid, name: '途客圈战队', authorId: userId, members: [userId1, userId2, ... ], createdAt: Date()}
Teams = new Meteor.Collection 'teams'

# project = { _id: uuid, name: 'cayman', description: 'cayman is a project', authorId: null, parentId: null, teamId: teamId, createdAt: Date() }
Projects = new Meteor.Collection 'projects'

# spark = {
# _id: uuid, type: 'idea', authorId: userId, auditTrails: [],
# currentOwner: userId, nextStep: 1, owners: [userId, ...], progress: 10
# title: 'blabla', content: 'blabla', priority: 1, supporters: [userId1, userId2, ...],
# projects: [projectId, ...], deadline: Date(), createdAt: Date(), teamId: teamId
# }
Sparks = new Meteor.Collection 'sparks'

# auditTrail = { _id: uuid, userId: teamId, content: 'bla bla', teamId: teamId, projectId: projectId, createdAt: Date()}
AuditTrails = new Meteor.Collection 'auditTrails'
