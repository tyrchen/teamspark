Meteor.methods

  createProject: (name, description, parentId) ->
    #{ _id: uuid, name: 'cayman', description: 'cayman is a project', authorId: null, parentId: null, teamId: teamId, createdAt: Date() }
    user = Meteor.user()
    now = ts.now()

    console.log name, description, parentId, user
    if ts.isFreelancer user
      return null

    projectId = Projects.insert
      name: name
      description: description
      authorId: user._id
      parent: parentId
      teamId: user.teamId
      createdAt: now

    # auditTrail = { _id: uuid, userId: teamId, content: 'bla bla', teamId: teamId, projectId: projectId, createdAt: Date()}
    AuditTrails.insert
      userId: user._id
      content: "#{user.username}创建了新的项目：#{name}"
      teamId: user.teamId
      projectId: projectId
      createdAt: now

    return projectId

  updateProject: (id, description) ->
    # update project description
    return

  moveProject: (id, newParentId) ->
    # update project parent. need to consider spark project changes
    return