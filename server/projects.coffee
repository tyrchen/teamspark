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
    return

  moveProject: (id, newParentId) ->
    # update project parent. need to consider spark project changes
    return