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

ts.getNow = ->
  (new Date()).getTime()

ts.isStaff = (team) -> Meteor.user()._id isnt team.authorId
ts.isFreelancer = (user) -> not user.teamId
