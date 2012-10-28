Meteor.methods
  createAudit: (content, projectId, sparkId=null) ->
    # auditTrail = { _id: uuid, userId: teamId, content: 'bla bla', teamId: teamId, projectId: projectId, createdAt: Date()}
    user = Meteor.user()
    console.log 'create audit:', content, projectId, sparkId
    AuditTrails.insert
      userId: user._id
      content: content
      teamId: user.teamId
      projectId: projectId
      createdAt: ts.now()

  addPoints: (count) ->
    Meteor.users.update Meteor.userId(), $inc: points: count

  online: (isOnline=true) ->
    if Meteor.userId()
      profile = Profiles.findOne userId: Meteor.userId()
      #console.log "user #{Meteor.user().username} online: #{isOnline}, profile: #{profile.username}"
      now = ts.now()
      if profile
        if not isOnline
          # online to offline, calculate the seconds user spent on team spark
          seconds = Math.floor((now - profile.lastActive)/1000)
          Profiles.update {userId: profile.userId}, {$set: {online: isOnline}, $inc: {totalSeconds: seconds}}
        else
          # offline to online, start record time spent
          Profiles.update {userId: profile.userId}, {$set: {online: isOnline, lastActive: now}}
      else
        # TODO: work around. should do this in after user create hook
        user = Meteor.user()
        Profiles.insert
          userId: user._id
          username: user.username
          online: isOnline
          teamId: user.teamId
          totalSeconds: 0

  createProject: (name, description, parentId) ->
    #{ _id: uuid, name: 'cayman', description: 'cayman is a project', authorId: null, parentId: null, teamId: teamId, createdAt: Date() }
    user = Meteor.user()
    now = ts.now()

    console.log 'creating project:', name, description, parentId, user.username
    if ts.isFreelancer user
      return null

    projectId = Projects.insert
      name: name
      description: description
      authorId: user._id
      parent: parentId
      teamId: user.teamId
      createdAt: now

    Meteor.call 'createAudit', "#{user.username}创建了新的项目：#{name}", projectId

    return projectId

  updateProject: (id, description) ->
    # update project description
    return ''

  moveProject: (id, newParentId) ->
    # update project parent. need to consider spark project changes
    return ''

  removeProject: (id) ->
    project = Projects.findOne _id: id
    if not project?.parent and Sparks.find(projects:id).count() is 0
      Projects.remove id