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