# access control
AuditTrails.allow
  insert: (userId, item) ->
    user = Meteor.users.findOne _id: userId
    item.teamId is user.teamId
  update: (userId, items, fields, modifier) -> false
  remove: (userId, items) -> false

Meteor.users.allow
  insert: (userId, item) -> false
  update: (userId, items, fields, modifier) ->
    userId is Meteor.userId()
  remove: (userId, items) -> false

Teams.allow
  insert: (userId, item) -> true
  update: (userId, items, fields, modifier) ->
    _.all items, (item) ->
      item.authorId is userId
  remove: (userId, items) -> false

Profiles.allow
  insert: (userId, item) -> false
  update: (userId, items, fields, modifier) ->
    _.all items, (item) ->
      item.userId is userId
  remove: (userId, items) -> false

team_access =
  insert: (userId, item) ->
    team = Teams.findOne _id: item.teamId
    userId in team.members
  update: (userId, items, fields, modifier) ->
    user = Meteor.users.findOne _id: userId
    _.all items, (item) ->
      item.teamId is user.teamId
  remove: (userId, items) -> false

Projects.allow team_access

Sparks.allow team_access

Tags.allow team_access

DayStats.allow team_access

WeekStats.allow team_access

