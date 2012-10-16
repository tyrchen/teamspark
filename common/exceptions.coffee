ts = ts || {}
ts.exp = ts.exp || {}

class ts.exp.Exception
  name: 'undefined'
  message: 'no description'
  constructor: (name, message) ->
    @name = name
    @message = message

class ts.exp.AccessDeniedException extends ts.exp.Exception
  constructor: (message) ->
    super 'Access Denied', message

class ts.exp.InvalidValueException extends ts.exp.Exception
  constructor: (message) ->
    super 'Invalid Value', message