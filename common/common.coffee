ts = ts || {}

class ts.Exception
  name: 'undefined'
  message: 'no description'
  constructor: (name, message) ->
    @name = name
    @message = message

class ts.AccessDeniedException extends ts.Exception
  constructor: (message) ->
    super 'Access Denied', message

class ts.InvalidValueException extends ts.Exception
  constructor: (message) ->
    super 'Invalid Value', message

ts.now = ->
  (new Date()).getTime()

ts.currentTeam = ->
  Teams.findOne _id: Meteor.user().teamId

ts.isStaff = (team) -> team and Meteor.user()._id is team.authorId
ts.isFreelancer = (user) -> not user.teamId

