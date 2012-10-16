Meteor.methods
  hire: (user, team) ->

    if not ts.isStaff team
      throw new ts.exp.AccessDeniedException('Only team staff can hire team members')

    if not ts.isFreelancer user
      throw new ts.exp.InvalidValueException('Only freelancer can be hired by a team')

    Meteor.users.update user._id, $set: {teamId: team._id}
    Teams.update team._id, $addToSet: {members: user._id}
    return true

  layoff: (user, team) ->
    if not ts.isStaff team
      throw new ts.exp.AccessDeniedException('Only team staff can layoff team members')

    if user._id is team.authorId
      throw new ts.exp.AccessDeniedException('team admin cannot be layed off')

    if not ts.isFreelancer user
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

  updateMembers: (added_ids, removed_ids) ->
    team = ts.currentTeam()
    console.log added_ids, removed_ids
    for id in added_ids
      user = Meteor.users.findOne _id: id
      if user
        Meteor.call 'hire', user, team

    for id in removed_ids
      user = Meteor.users.findOne _id: id
      if user
        Meteor.call 'layoff', user, team