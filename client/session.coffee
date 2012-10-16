ts = ts || {}
ts.getSession = (name) ->
  Session.get name

ts.setSession = (name, value) ->
  Session.set name, value


ts.members = ->
  Meteor.users.find teamId: ts.State.teamId.get()

ts.State = {}

_.extend ts.State,
  # current user's team
  teamId:
    #get: -> ts.getSession 'teamId'  # TODO: replace it with user's team
    get: -> Meteor.user().teamId

  # filter the sparks by current owner or team. Can be 'user' | 'team'
  filterType:
    get: -> ts.getSession 'filterType' || 'team'
    set: (value)-> ts.setSession 'filterType', value

  # filter the sparks by special type or project name. can be 'important' | 'urgent' | 'all' | projectName
  filterSelected:
    get: -> ts.getSession 'filterSelected' || null
    set: (value)-> ts.setSession 'filterSelected', value

  # spark display type. 'wall' or 'board'
  sparkDisplay:
    get: -> ts.getSession 'sparkDisplay' || 'wall'
    set: (value)-> ts.setSession 'sparkDisplay', value

  # spark order for display. can be 'createdAt' | 'updatedAt'
  sparkOrder:
    get: -> ts.getSession 'sparkOrder' || 'updatedAt'
    set: (value)-> ts.setSession 'sparkOrder', value

  # spark type for filter. can be 'idea' | 'bug' | 'requirement' | 'task'
  sparkTypeFilter:
    get: -> ts.getSession 'sparkTypeFilter' || null
    set: (value)-> ts.setSession 'sparkTypeFilter', value

  # spark priority filter. can be 1 - red | 2 - orange | 3 - yellow | 4 - green | 5 - gray
  sparkPriorityFilter:
    get: -> ts.getSession 'sparkPriorityFilter' || null
    set: (value)-> ts.setSession 'sparkPriorityFilter', value

  # spark author filter. can be author name
  sparkAuthorFilter:
    get: -> ts.getSession 'sparkAuthorFilter' || null
    set: (value)-> ts.setSession 'sparkAuthorFilter', value

  # spark progress filter. can be 'not started | just started | half down | almost done | done' - use visual graph
  sparkProgressFilter:
    get: -> ts.getSession 'sparkProgressFilter' || null
    set: (value)-> ts.setSession 'sparkProgressFilter', value

  # activity display type. can be 'team' | 'project'
  activityDisplay:
    get: -> ts.getSession 'activityDisplay' || 'team'
    set: (value)-> ts.setSession 'activityDisplay', value

  # activity selected filter. can be 'userId' | 'projectId'
  activitySelected:
    get: -> ts.getSession 'activityType' || null
    set: (value)-> ts.setSession 'activityType', value

