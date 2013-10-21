Meteor.methods
  addToTeam: (userId, teamId) ->
    currentUser = Meteor.user()
    if currentUser.teamId is teamId
      Meteor.users.update userId, $set: teamId: teamId
      Teams.update teamId, $addToSet: {members: userId}

  removeFromTeam: (userId, teamId) ->
    if currentUser.teamId is teamId
      Meteor.users.update userId, $set: teamId: null
      Teams.update teamId, $pull: {members: userId}