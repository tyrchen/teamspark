if Meteor.is_server
  Meteor.publish 'teams', ->
    Teams.find()

  Meteor.publish null, ->
    # publish desired user data to client
    Meteor.users.find {}, {fields: {
      profile: 1
      username: 1
      teamId: 1
      avatar: 1
      url: 1
      location: 1
      description: 1
      points: 1
    }, sort: {points: -1}}

  Meteor.publish 'projects', (teamId) ->
    Projects.find teamId: teamId

  Meteor.publish 'sparks', (teamId) ->
    Sparks.find {teamId: teamId}, {sort: 'updateddAt': -1}

  #Meteor.publish 'auditTrails', (teamId) ->
  #  AuditTrails.find teamId: teamId

  Meteor.publish 'notifications', (userId) ->
    Notifications.find {recipientId: $in: [userId, null]}, {sort: 'level': -1}

if Meteor.is_client
  Meteor.autosubscribe ->
    teamId = ts.State.teamId.get()
    Meteor.subscribe 'teams'
    if teamId
      Meteor.subscribe 'projects', teamId, ->
        console.log 'projects loaded'
        project = Projects.findOne {}
        if project
          Router.setProject project.name
      Meteor.subscribe 'sparks', teamId, ->
        console.log 'sparks loaded'
        ts.State.loaded.set true
      #Meteor.subscribe 'auditTrails', teamId
      Meteor.subscribe 'notifications', Meteor.userId(), ->
        console.log 'notifications loaded'





