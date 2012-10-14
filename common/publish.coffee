if Meteor.is_server
  Meteor.publish 'teams', ->
    Teams.find()

  Meteor.publish null, ->
    # publish desired user data to client

  Meteor.publish 'members', (teamId) ->
    Meteor.users.find teamId: $in: [teamId, null], fields:
      profile: 1
      username: 1
      teamId: 1
      avatar: 1
      url: 1
      location: 1

  Meteor.publish 'projects', (teamId) ->
    Projects.find teamId: teamId

  Meteor.publish 'sparks', (teamId) ->
    Sparks.find teamId: teamId, sort: 'updateddAt': -1

  Meteor.publish 'auditTrails', (teamId) ->
    AuditTrails.find teamId: teamId

if Meteor.is_client
  Meteor.autosubscribe ->
    teamId = ts.State.teamId.get()
    Meteor.subscribe 'teams'
    if teamId
      Meteor.subscribe 'projects', teamId
      Meteor.subscribe 'sparks', teamId
      Meteor.subscribe 'auditTrails', teamId





