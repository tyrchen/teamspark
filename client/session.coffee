getSession = (name) ->
  Session.get name

setSession = (name, value) ->
  Session.set name, value

State = {}

_.extend State,

  # current user's team
  teamId:
    #get: -> getSession 'teamId'  # TODO: replace it with user's team
    get: -> Meteor.user.teamId

  # filter the sparks by current owner or team. Can be 'user' | 'team'
  filterType:
    get: -> getSession 'filterType' || 'team'
    set: (value)-> setSession 'filterType', value

  # filter the sparks by special type or project name. can be 'important' | 'urgent' | 'all' | projectName
  filterSelected:
    get: -> getSession 'filterSelected' || null
    set: (value)-> setSession 'filterSelected', value

  # spark display type. 'wall' or 'board'
  sparkDisplay:
    get: -> getSession 'sparkDisplay' || 'wall'
    set: (value)-> setSession 'sparkDisplay', value

  # spark order for display. can be 'createdAt' | 'updatedAt'
  sparkOrder:
    get: -> getSession 'sparkOrder' || 'updatedAt'
    set: (value)-> setSession 'sparkOrder', value

  # spark type for filter. can be 'idea' | 'bug' | 'requirement' | 'task'
  sparkTypeFilter:
    get: -> getSession 'sparkTypeFilter' || null
    set: (value)-> setSession 'sparkTypeFilter', value

  # spark priority filter. can be 1 - red | 2 - orange | 3 - yellow | 4 - green | 5 - gray
  sparkPriorityFilter:
    get: -> getSession 'sparkPriorityFilter' || null
    set: (value)-> setSession 'sparkPriorityFilter', value

  # spark author filter. can be author name
  sparkAuthorFilter:
    get: -> getSession 'sparkAuthorFilter' || null
    set: (value)-> setSession 'sparkAuthorFilter', value

  # spark progress filter. can be 'not started | just started | half down | almost done | done' - use visual graph
  sparkProgressFilter:
    get: -> getSession 'sparkProgressFilter' || null
    set: (value)-> setSession 'sparkProgressFilter', value

  # activity display type. can be 'team' | 'project'
  activityDisply:
    get: -> getSession 'activityDisply' || 'team'
    set: (value)-> setSession 'activityDisply', value

  # activity selected filter. can be 'userId' | 'projectId'
  activitySelected:
    get: -> getSession 'activityType' || null
    set: (value)-> setSession 'activityType', value

