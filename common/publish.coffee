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

  Meteor.publish 'profiles', (teamId) ->
    Profiles.find teamId: teamId

  Meteor.publish 'projects', (teamId) ->
    Projects.find teamId: teamId

  Meteor.publish 'sparks', (projectId) ->
    Sparks.find {'projects.0': projectId}, {sort: 'updateddAt': -1}

  #Meteor.publish 'auditTrails', (teamId) ->
  #  AuditTrails.find teamId: teamId

  Meteor.publish 'notifications', (userId) ->
    Notifications.find {recipientId: userId}, {sort: 'createdAt': -1}

  Meteor.publish 'dayStats', (teamId) ->
    DayStats.find {teamId: teamId}, {sort: 'date': 1}

  Meteor.publish 'tags', (teamId) ->
    Tags.find {teamId: teamId}, {sort: 'count': -1}

if Meteor.is_client
  Meteor.autosubscribe ->
    teamId = ts.State.teamId.get()
    Meteor.subscribe 'teams'
    if teamId
      Meteor.subscribe 'projects', teamId, ->
        console.log 'projects loaded'

      projectId = ts.State.filterSelected.get()
      if projectId
        Meteor.subscribe 'sparks', projectId, ->
          console.log 'sparks loaded'
          ts.State.loaded.set true

      #Meteor.subscribe 'auditTrails', teamId

      Meteor.subscribe 'notifications', Meteor.userId(), ->
        console.log 'notifications loaded'

      Meteor.subscribe 'profiles', teamId, ->
        console.log 'profiles loaded'

      Meteor.subscribe 'dayStats', teamId, ->
        console.log 'dayStats loaded'

      Meteor.subscribe 'tags', teamId, ->
        console.log 'tags loaded'

