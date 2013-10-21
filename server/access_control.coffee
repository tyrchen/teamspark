# access control
AuditTrails.allow
  insert: (userId, item) ->
    user = Meteor.users.findOne _id: userId
    item.teamId is user.teamId
  update: (userId, item, fields, modifier) -> false
  remove: (userId, item) -> false

Meteor.users.allow
  insert: (userId, item) -> false
  update: (userId, item, fields, modifier) -> userId is item._id
  remove: (userId, item) -> false

Teams.allow
  insert: (userId, item) -> true
  update: (userId, item, fields, modifier) -> userId in item.members
  remove: (userId, item) -> false

Profiles.allow
  insert: (userId, item) -> true
    #team = Teams.find(_id: item.teamId)
    #console.log item, team
    #team.authorId is userId
  update: (userId, item, fields, modifier) -> item.userId is userId
  remove: (userId, item) -> false

team_access =
  insert: (userId, item) ->
    team = Teams.findOne _id: item.teamId
    userId in team.members
  update: (userId, item, fields, modifier) ->
    user = Meteor.users.findOne _id: userId
    item.teamId is user.teamId
  remove: (userId, item) -> false

Projects.allow team_access

Sparks.allow team_access

Tags.allow team_access

DayStats.allow team_access

WeekStats.allow team_access

