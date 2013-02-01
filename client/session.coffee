ts = ts || {}
ts.getSession = (name) ->
  Session.get name

ts.setSession = (name, value) ->
  if name not in ['showSpark', 'teamId', 'loaded']
    # TODO: fix me. this is a workaround to clear notification entry and show sparks
    #console.log 'setSession:', name, value
    Session.set 'showSpark', null

  Session.set name, value


ts.members = {}
ts.members.all = ->
  Meteor.users.find teamId: ts.State.teamId.get()

ts.members.waiting = ->
  Meteor.users.find teamId: null

ts.members.ordered = ->
  return ts.members.all().fetch()

ts.tags = {}
ts.tags.all =  ->
  query = {'teamId': ts.State.teamId.get()}
  projectId = ts.State.filterSelected.get()
  if projectId isnt 'all'
    project = Projects.findOne _id: projectId
    if project
      if project.parent
        query['projectId'] = project.parent
      else
        query['projectId'] = projectId

  Tags.find query

ts.editor = ->
  new nicEditor
    fullPanel : false
    buttonList : ['save','bold','italic','underline','left','center','right','ol','ul','fontSize','fontFamily','fontFormat','indent','outdent','link','forecolor','bgcolor'],
    iconsPath: '/nicEditorIcons.gif'


ts.State = {}

_.extend ts.State,
  # current user's team
  teamId:
    #get: -> ts.getSession 'teamId'  # TODO: replace it with user's team
    get: ->
      teamId = ts.getSession 'teamId'
      if not teamId
        user = Meteor.user()
        if user
          ts.setSession 'teamId', teamId
          return user.teamId
        return null
      else
        return teamId

  loaded:
    get: -> ts.getSession('loaded') || false
    set: (value) -> ts.setSession 'loaded', value

  # filter the sparks by current owner or team. Can be 'user' | 'team'
  filterType:
    get: -> ts.getSession('filterType') || 'user'
    set: (value)-> ts.setSession 'filterType', value

  filterUser:
    get: -> ts.getSession('filterUser')?.id || 'all' #Meteor.userId()
    getName: -> ts.getSession('filterUser')?.username || 'All' #Meteor.user()?.username
    set: (value) -> ts.setSession 'filterUser', value

  # filter the sparks by special type or project name. can be 'important' | 'urgent' | 'all' | projectName
  filterSelected:
    get: -> ts.getSession('filterSelected')?.id || 'all'
    getName: -> ts.getSession('filterSelected')?.name || 'All'
    set: (value)-> ts.setSession 'filterSelected', value

  # filter the sparks by shortcut
  filterShortcut:
    get: -> ts.getSession('filterShortcut') || 'unfinished'
    set: (value) -> ts.setSession 'filterShortcut', value

  # spark display type. 'wall' or 'board'
  sparkDisplay:
    get: -> ts.getSession('sparkDisplay') || 'wall'
    set: (value)-> ts.setSession 'sparkDisplay', value

  # spark order for display. can be 'createdAt' | 'updatedAt'
  sparkOrder:
    get: -> ts.getSession('sparkOrder')?.id || 'createdAt'
    getName: -> ts.getSession('sparkOrder')?.name || 'Created'
    set: (value)-> ts.setSession 'sparkOrder', value

  # spark type for filter. can be 'idea' | 'bug' | 'feature' | 'task'
  sparkTypeFilter:
    get: -> ts.getSession('sparkTypeFilter')?.id || 'all'
    getName: -> ts.getSession('sparkTypeFilter')?.name || 'All'
    set: (value)-> ts.setSession 'sparkTypeFilter', value

  # spark priority filter. can be 1 - red | 2 - orange | 3 - yellow | 4 - green | 5 - gray
  sparkPriorityFilter:
    get: -> ts.getSession('sparkPriorityFilter')?.id || 'all'
    getName: -> ts.getSession('sparkPriorityFilter')?.name || 'All'
    set: (value)-> ts.setSession 'sparkPriorityFilter', value

  # spark author filter. can be author name
  sparkAuthorFilter:
    get: -> ts.getSession('sparkAuthorFilter')?.id || 'all'
    getName: -> ts.getSession('sparkAuthorFilter')?.name || 'All'
    set: (value)-> ts.setSession 'sparkAuthorFilter', value

  # spark current owner filter. can be author name
  sparkOwnerFilter:
    get: -> ts.getSession('sparkOwnerFilter')?.id || 'all'
    getName: -> ts.getSession('sparkOwnerFilter')?.name || 'All'
    set: (value) -> ts.setSession 'sparkOwnerFilter', value

  # spark progress filter. can be 'not started | just started | half down | almost done | done' - use visual graph
  sparkProgressFilter:
    get: -> ts.getSession('sparkProgressFilter')?.id || 'all'
    getName: -> ts.getSession('sparkProgressFilter')?.id || 'All'
    set: (value) -> ts.setSession 'sparkProgressFilter', value

  sparkFinishFilter:
    get: -> ts.getSession('sparkFinishFilter')?.id
    getName: -> ts.getSession('sparkFinishFilter')?.name || 'Unfinished'
    set: (value) -> ts.setSession 'sparkFinishFilter', value

  sparkVerifyFilter:
    get: -> ts.getSession('sparkVerifyFilter')?.id
    getName: -> ts.getSession('sparkVerifyFilter')?.name || 'Unverified'
    set: (value) -> ts.setSession 'sparkVerifyFilter', value

  sparkDeadlineFilter:
    get: -> ts.getSession('sparkDeadlineFilter')?.id || 'all'
    getName: -> ts.getSession('sparkDeadlineFilter')?.name || 0
    set: (value) -> ts.setSession 'sparkDeadlineFilter', value

  sparkTagFilter:
    get: -> ts.getSession('sparkTagFilter')?.id || 'all'
    getName: -> ts.getSession('sparkTagFilter')?.name || 'All'
    set: (value) -> ts.setSession 'sparkTagFilter', value

  clearFilters: ->
    ts.State.sparkDeadlineFilter.set null
    ts.State.sparkFinishFilter.set null
    ts.State.sparkProgressFilter.set null
    ts.State.sparkOwnerFilter.set null
    ts.State.sparkAuthorFilter.set null
    ts.State.sparkPriorityFilter.set null
    ts.State.sparkTypeFilter.set null
    ts.State.sparkFinishFilter.set {id: 1, name: 'Unfinished'}
    ts.State.sparkTagFilter.set null
    ts.State.sparkVerifyFilter.set {id: 0, name: 'All'}

  sparkToCreate:
    get: -> ts.getSession('sparkToCreate')?.id || 'idea'
    getName: -> ts.getSession('sparkToCreate')?.name || 'Idea'
    set: (value) -> ts.setSession 'sparkToCreate', value

  # activity display type. can be 'team' | 'project'
  activityDisplay:
    get: -> ts.getSession('activityDisplay') || 'team'
    set: (value)-> ts.setSession 'activityDisplay', value

  # activity selected filter. can be 'userId' | 'projectId'
  activitySelected:
    get: -> ts.getSession('activityType') || null
    set: (value)-> ts.setSession 'activityType', value

  showSpark:
    get: -> ts.getSession('showSpark') || null
    set: (value) -> ts.setSession 'showSpark', value

  showContent:
    get: -> ts.getSession('showContent') || 'sparks'
    set: (value) -> ts.setSession 'showContent', value

  currentPage:
    get: -> ts.getSession('currentPage') || 2
    set: (value) -> ts.setSession 'currentPage', value

Meteor.startup ->
  ts.State.sparkFinishFilter.set {id: 1, name: 'Unfinished'}
  ts.State.sparkVerifyFilter.set {id: 0, name: 'All'}