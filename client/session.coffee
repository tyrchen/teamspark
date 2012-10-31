ts = ts || {}
ts.getSession = (name) ->
  Session.get name

ts.setSession = (name, value) ->
  if name not in ['showSpark', 'teamId']
    # TODO: fix me. this is a workaround to clear notification entry and show sparks
    console.log 'setsession: ', name, value
    Session.set 'showSpark', null

  Session.set name, value


ts.members = {}
ts.members.all = ->
  Meteor.users.find teamId: ts.State.teamId.get()

ts.members.ordered = ->
  return ts.members.all().fetch()


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
    get: -> ts.getSession('filterType') || 'team'
    set: (value)-> ts.setSession 'filterType', value

  # filter the sparks by special type or project name. can be 'important' | 'urgent' | 'all' | projectName
  filterSelected:
    get: -> ts.getSession('filterSelected')?.id || 'all'
    getName: -> ts.getSession('filterSelected')?.name || '全部'
    set: (value)-> ts.setSession 'filterSelected', value

  # spark display type. 'wall' or 'board'
  sparkDisplay:
    get: -> ts.getSession('sparkDisplay') || 'wall'
    set: (value)-> ts.setSession 'sparkDisplay', value

  # spark order for display. can be 'createdAt' | 'updatedAt'
  sparkOrder:
    get: -> ts.getSession('sparkOrder')?.id || 'createdAt'
    getName: -> ts.getSession('sparkOrder')?.name || '最近创建'
    set: (value)-> ts.setSession 'sparkOrder', value

  # spark type for filter. can be 'idea' | 'bug' | 'requirement' | 'task'
  sparkTypeFilter:
    get: -> ts.getSession('sparkTypeFilter')?.id || 'all'
    getName: -> ts.getSession('sparkTypeFilter')?.name || '全部'
    set: (value)-> ts.setSession 'sparkTypeFilter', value

  # spark priority filter. can be 1 - red | 2 - orange | 3 - yellow | 4 - green | 5 - gray
  sparkPriorityFilter:
    get: -> ts.getSession('sparkPriorityFilter')?.id || 'all'
    getName: -> ts.getSession('sparkPriorityFilter')?.name || '全部'
    set: (value)-> ts.setSession 'sparkPriorityFilter', value

  # spark author filter. can be author name
  sparkAuthorFilter:
    get: -> ts.getSession('sparkAuthorFilter')?.id || 'all'
    getName: -> ts.getSession('sparkAuthorFilter')?.name || '全部'
    set: (value)-> ts.setSession 'sparkAuthorFilter', value

  # spark current owner filter. can be author name
  sparkOwnerFilter:
    get: -> ts.getSession('sparkOwnerFilter')?.id || 'all'
    getName: -> ts.getSession('sparkOwnerFilter')?.name || '全部'
    set: (value) -> ts.setSession 'sparkOwnerFilter', value

  # spark progress filter. can be 'not started | just started | half down | almost done | done' - use visual graph
  sparkProgressFilter:
    get: -> ts.getSession('sparkProgressFilter')?.id || 'all'
    getName: -> ts.getSession('sparkProgressFilter')?.id || '全部'
    set: (value) -> ts.setSession 'sparkProgressFilter', value

  sparkFinishFilter:
    get: -> ts.getSession('sparkFinishFilter')?.id
    getName: -> ts.getSession('sparkFinishFilter')?.name || '未完成'
    set: (value) -> ts.setSession 'sparkFinishFilter', value

  sparkDeadlineFilter:
    get: -> ts.getSession('sparkDeadlineFilter')?.id || 'all'
    getName: -> ts.getSession('sparkDeadlineFilter')?.name || 0
    set: (value) -> ts.setSession 'sparkDeadlineFilter', value

  clearFilters: ->
    ts.State.sparkDeadlineFilter.set null
    ts.State.sparkFinishFilter.set null
    ts.State.sparkProgressFilter.set null
    ts.State.sparkOwnerFilter.set null
    ts.State.sparkAuthorFilter.set null
    ts.State.sparkPriorityFilter.set null
    ts.State.sparkTypeFilter.set null
    ts.State.sparkFinishFilter.set {id: 1, name: '未完成'}

  sparkToCreate:
    get: -> ts.getSession('sparkToCreate')?.id || 'idea'
    getName: -> ts.getSession('sparkToCreate')?.name || '想法'
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


Meteor.startup ->
  ts.State.sparkFinishFilter.set {id: 1, name: '未完成'}