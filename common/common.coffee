ts = ts || {}

ts.now = ->
  (new Date()).getTime()

ts.toDate = (d)->
  (new Date(new Date(d).toDateString())).getTime()

ts.formatDate = (date) ->
  # to ensure date is a Date instance
  date = new Date(date)
  y = date.getFullYear()
  m = date.getMonth() + 1
  d = date.getDate()
  if m < 9
    m = '0' + m

  if d < 9
    d = '0' + d

  return "#{y}-#{m}-#{d}"

ts.formatTime = (seconds) ->
  hours = Math.floor(seconds/3600)
  remainder = seconds % 3600
  minutes = Math.floor(remainder/60)
  seconds = remainder % 60
  if hours > 0
    return "#{hours}小时#{minutes}分钟"
  else if minutes > 0
    return "#{minutes}分钟"
  else
    return "#{seconds}秒"

ts.currentTeam = ->
  user = Meteor.user()
  if user
    return Teams.findOne _id: Meteor.user().teamId
  return null


ts.isStaff = (team=null) ->
  user = Meteor.user()
  if not team
    team = Teams.findOne _id: user.teamId
  team and user._id is team.authorId

ts.isFreelancer = (user) -> not user.teamId

# project model functions
ts.projects = ts.projects || {}
ts.projects.writable = (project) ->
  if not project.teamId?
    project = Projects.findOne _id: project
  project.teamId is Meteor.user().teamId

ts.projects.hasProject = -> Projects.find().count()
ts.projects.all = -> Projects.find()
ts.projects.ordered = -> ts.projects.all()
ts.projects.parents = -> Projects.find {parent: null}, {sort: {createdAt: 1}}
ts.projects.children = (id)-> Projects.find parent: id

# spark model functions
ts.sparks = ts.sparks || {}
ts.sparks.types = ->
  [
    {name: '想法', id: 'idea', icon: 'icon-magic'},
    {name: 'BUG', id: 'bug', icon: 'icon-exclamation-sign'},
    {name: '需求', id: 'feature', icon: 'icon-money'},
    {name: '任务', id: 'task', icon: 'icon-inbox'},
    {name: '改进', id: 'improvement', icon: 'icon-wrench'}
  ]

ts.sparks.typesPos = {'idea': 1, 'bug': 2, 'feature': 3, 'task': 4, 'improvement': 5}

ts.sparks.type = (spark) ->
  if spark.type
    type = spark.type
  else
    type = spark
  _.find ts.sparks.types(), (item) => item.id is type

ts.sparks.isAuthor = (spark) ->
  if not spark.authorId?
    spark = Sparks.findOne _id: spark
  spark.authorId is Meteor.user()._id

ts.sparks.writable = (spark) ->
  if not spark.teamId?
    spark = Sparks.findOne _id: spark
  spark.teamId is Meteor.user().teamId

#ts.sparks.total = (projectId) -> Sparks.find(projects: projectId).count()
#ts.sparks.totalFinished = (projectId) -> Sparks.find(projects: projectId, finished: true).count()
ts.sparks.totalSubmitted = (authorId, projectId=null) ->
  ts.sparks.submittedItems(authorId, projectId).count()

ts.sparks.submittedItems = (authorId, projectId=null) ->
  query = [authorId: authorId]
  if projectId
    query.push projects: projectId

  Sparks.find $and: query

ts.sparks.totalUnfinished = (projectId=null, ownerId=null) ->
  ts.sparks.unfinishedItems(projectId, ownerId).count()

ts.sparks.unfinishedItems = (projectId=null, ownerId=null) ->
  ts.sparks.filteredFinishItems projectId, ownerId

ts.sparks.totalFinished = (projectId=null, ownerId=null) ->
  ts.sparks.finishedItems(projectId, ownerId).count()

ts.sparks.finishedItems = (projectId=null, ownerId=null) ->
  ts.sparks.filteredFinishItems projectId, ownerId, true


ts.sparks.filteredFinishItems = (projectId=null, ownerId=null, finished=false) ->
  #query = [finished: finished]
  query = []
  if projectId
    query.push projects: projectId

  if ownerId
    if finished
      query.push finishers: ownerId
    else
      query.push owners: ownerId
  else
    query.push finished: finished

  if query.length > 0
    Sparks.find $and: query
  else
    Sparks.find {}

ts.sparks.importantItems = (projectId=null, ownerId=null) ->
  query = [
    {finished: false},
    {priority: $gt: ts.consts.prio.HIGH}
  ]

  if projectId
    query.push projects: projectId

  if ownerId
    query.push owners: ownerId

  Sparks.find $and: query

ts.sparks.totalImportant = (projectId=null, ownerId=null) ->
  ts.sparks.importantItems(projectId, ownerId).count()

ts.sparks.urgentItems = (projectId=null, ownerId=null) ->
  # tasks expire in 3 days
  time = ts.now() + ts.consts.EXPIRE_IN_3_DAYS
  query = [
    deadline: $and: $ne: null, $lt:  time
  ]

  if projectId
    query.push projects: projectId

  if ownerId
    query.push owners: ownerId

  Sparks.find query

ts.sparks.totalUrgent = (projectId) -> ts.sparks.urgentItems(projectId).count()

ts.sparks.isUrgent = (spark) ->
  time = ts.now() + ts.consts.EXPIRE_IN_3_DAYS
  spark.deadline and spark.deadline < time

ts.sparks.isImportant = (spark) ->
  spark.priority >= ts.consts.prio.HIGH

ts.sparks.hasSupported = (spark) ->
  _.find spark.supporters, (id) -> Meteor.user()._id is id

ts.sparks.allOwners = (spark) ->
  _.map spark.owners, (id) -> Meteor.users.findOne id

ts.sparks.currentOwner = (spark) ->
  if spark.owners[0]
    return Meteor.users.findOne spark.owners[0]
  else
    return null

ts.sparks.query = (needProject=true) ->
  project = ts.State.filterSelected.get()
  filterType = ts.State.filterType.get()
  filterUser = ts.State.filterUser.get()

  type = ts.State.sparkTypeFilter.get()
  priority = ts.State.sparkPriorityFilter.get()
  author = ts.State.sparkAuthorFilter.get()
  owner = ts.State.sparkOwnerFilter.get()
  progress = ts.State.sparkProgressFilter.get()
  deadline = ts.State.sparkDeadlineFilter.get()
  finish = ts.State.sparkFinishFilter.get()
  tag = ts.State.sparkTagFilter.get()
  verify = ts.State.sparkVerifyFilter.get()

  showSpark = ts.State.showSpark.get()

  user = Meteor.user()
  query = []


  if needProject and project isnt 'all'
    p = Projects.findOne _id: project
    if p?.parent
      query.push projects: project
    else
      query.push projects: [project]

  # only filter owners if the spark is not finished
  if filterType is 'user' and finish isnt 2 and author is 'all'
    if filterUser isnt 'all'
      query.push owners: filterUser

  if type isnt 'all'
    query.push type: type

  if priority isnt 'all'
    query.push priority: $gte: priority

  if author isnt 'all'
    query.push authorId: author

  if owner isnt 'all'
    query.push 'owners': owner

  if progress isnt 'all'
    query.push progress: progress

  if deadline isnt 'all'
    query.push deadline: {$gt: ts.now(), $lte: deadline + ts.now()}

  if finish isnt 0
    if finish is 1
      query.push finished: false
    else
      if filterType is 'user' and author is 'all'
        if filterUser isnt 'all'
          query.push finishers: filterUser
      query.push finished: true

  if verify isnt 0
    if verify is 1
      query.push verified: false
    else
      query.push verified: true

  if tag isnt 'all'
    query.push tags: tag
  #console.log 'query:', query
  return query

ts.audits = ts.audits || {}
ts.audits.all = (userId=null, projectId=null) ->
  query = []
  if userId
    query.push userId: userId

  if projectId
    query.push projectId: projectId

  AuditTrails.find {$and: query}, {sort: createdAt: -1}