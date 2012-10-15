Meteor.methods
  hire: (user, team) ->

    if not ts.isStaff team
      throw new ts.AccessDeniedException('Only team staff can hire team members')

    if not ts.isFreelancer(user)
      throw new ts.InvalidValueException('Only freelancer can be hired by a team')

    Meteor.users.update user._id, $set: {teamId: team._id}
    Teams.update team._id, $addToSet: {members: user._id}
    return true

  layoff: (user, team) ->
    if ts.isStaff team
      throw new ts.AccessDeniedException('Only team staff can layoff team members')

    if not ts.isFreelancer
      Meteor.users.update user._id, $set: {teamId: null}
      Teams.update team._id, $pull: {members: user._id}

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