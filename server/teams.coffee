Meteor.methods
  hire: (user, team) ->

    if not ts.isStaff team
      throw new ts.exp.AccessDeniedException('Only team staff can hire team members')

    if not ts.isFreelancer user
      throw new ts.exp.InvalidValueException('Only freelancer can be hired by a team')

    Meteor.users.update user._id, $set: {teamId: team._id}
    Teams.update team._id, $addToSet: {members: user._id}
    AuditTrails.insert
      userId: user._id
      content: "#{user.username}加入到了#{team.name}"
      teamId: team._id
      projectId: null
      createdAt: ts.now()
    return true

  layoff: (user, team) ->
    if not ts.isStaff team
      throw new ts.exp.AccessDeniedException('Only team staff can layoff team members')

    if user._id is team.authorId
      throw new ts.exp.AccessDeniedException('team admin cannot be layed off')

    if not ts.isFreelancer user
      Meteor.users.update user._id, $set: {teamId: null}
      Teams.update team._id, $pull: {members: user._id}
      AuditTrails.insert
        userId: user._id
        content: "#{user.username}退出了#{team.name}"
        teamId: team._id
        projectId: null
        createdAt: ts.now()

  updateMembers: (added_ids, removed_ids) ->
    team = ts.currentTeam()
    #console.log added_ids, removed_ids
    for id in added_ids
      user = Meteor.users.findOne _id: id
      if user
        Meteor.call 'hire', user, team

    for id in removed_ids
      user = Meteor.users.findOne _id: id
      if user
        Meteor.call 'layoff', user, team

