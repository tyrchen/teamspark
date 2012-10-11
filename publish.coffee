if Meteor.is_server
  Meteor.publish 'currentTeam', (teamId) ->
    Teams.findOne _id: teamId

  Meteor.publish 'teams', ->
    Teams.find()

  Meteor.publish null, ->
    # publish desired user data to client
    Meteor.users.find {}, fields:
      profile: 1
      username: 1
      teamId: 1
      avatar: 1
      url: 1
      location: 1

  Meteor.publish 'members', (teamId) ->
    Meteor.users.find teamId: teamId

  Meteor.publish 'projects', (teamId) ->
    Projects.find teamId: teamId

  Meteor.publish 'sparks', (teamId) ->
    Sparks.find teamId: teamId, sort: 'updateddAt': -1

  Meteor.publish 'auditTrails', (teamId) ->
    AuditTrails.find teamId: teamId

if Meteor.is_client
  Meteor.autosubscribe ->
    teamId = State.teamId.get()
    Meteor.subscribe 'teams'
    if teamId
      Meteor.subscribe 'currentTeam', teamId
      Meteor.subscribe 'members', teamId
      Meteor.subscribe 'projects', teamId
      Meteor.subscribe 'sparks', teamId
      Meteor.subscribe 'auditTrails', teamId





