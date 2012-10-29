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
          if seconds > 900
            # for most cases user do any operation should not exceed 15 mins
            seconds = 900
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

    recipients = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
    content = "#{user.username}创建了项目#{name}"
    Meteor.call 'notify', recipients, content, content, null
    return projectId

  updateProject: (id, description) ->
    # update project description
    user = Meteor.user()
    project = Projects.findOne _id: id
    recipients = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
    content = "#{user.username}修改了项目#{project.name}的描述"
    Meteor.call 'notify', recipients, content, content, null
    return ''

  moveProject: (id, newParentId) ->
    # update project parent. need to consider spark project changes
    user = Meteor.user()
    project = Projects.findOne _id: id
    parent = Projects.findOne _id: newParentId
    recipients = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
    content = "#{user.username}修改了项目#{project.name}的上级项目为#{parent.name}"
    Meteor.call 'notify', recipients, content, content, null
    return ''

  removeProject: (id) ->
    user = Meteor.user()
    project = Projects.findOne _id: id
    if not project?.parent and Sparks.find(projects:id).count() is 0
      Projects.remove id

      recipients = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
      content = "#{user.username}删除了项目#{project.name}"
      Meteor.call 'notify', recipients, content, content, null