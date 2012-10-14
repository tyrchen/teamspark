ts = ts || {}
ts.filteringTeam = ->
  ts.State.filterType == 'team'

ts.filteringUser = ->
  ts.State.filterType == 'user'
