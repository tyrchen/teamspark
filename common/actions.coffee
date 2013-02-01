Actions = {}

# team related
Actions.createTeam = (name) ->
  user = Meteor.user()
  id = Teams.insert
    name: name
    authorId: user._id
    members: [user._id]
    createdAt: ts.now()
    abbr: ""
    nextIssueId: 1

  console.log 'team id:', id
  Meteor.users.update user._id, '$set': 'teamId': id

Actions.hire = (user, team) ->

  if not ts.isStaff team
    throw new ts.exp.AccessDeniedException('Only team staff can hire team members')

  if not ts.isFreelancer user
    #throw new ts.exp.InvalidValueException('Only freelancer can be hired by a team')
    return

  Meteor.users.update user._id, $set: {teamId: team._id}
  Teams.update team._id, $addToSet: {members: user._id}
  if Profiles.find(userId: user._id).count() is 0
    Profiles.insert
      userId: user._id
      username: user.username
      online: true
      teamId: user.teamId
      totalSubmitted: 0
      totalUnfinished: 0
      totalFinished: 0
      lastActive: ts.now()
      teamId: team._id
      totalSeconds: 0

  AuditTrails.insert
    userId: user._id
    content: "#{user.username}加入到了#{team.name}"
    teamId: team._id
    projectId: null
    createdAt: ts.now()
  return true

Actions.layoff = (user, team) ->
  if not ts.isStaff team
    throw new ts.exp.AccessDeniedException('Only team staff can layoff team members')

  if user._id is team.authorId
    #throw new ts.exp.AccessDeniedException('team admin cannot be layed off')
    return

  if not ts.isFreelancer user
    Meteor.users.update user._id, $set: {teamId: null}
    Teams.update team._id, $pull: {members: user._id}
    AuditTrails.insert
      userId: user._id
      content: "#{user.username}退出了#{team.name}"
      teamId: team._id
      projectId: null
      createdAt: ts.now()

Actions.updateMembers = (added_ids, removed_ids) ->
  team = ts.currentTeam()
  for id in added_ids
    user = Meteor.users.findOne _id: id
    if user
      Actions.hire user, team

  for id in removed_ids
    user = Meteor.users.findOne _id: id
    if user
      Actions.layoff user, team

# project/user related
Actions.addPoints = (count) ->
  Meteor.users.update Meteor.userId(), $inc: points: count

Actions.createProject = (name, description, parentId) ->
  #{ _id: uuid, name: 'cayman', description: 'cayman is a project', authorId: null, parentId: null, teamId: teamId, createdAt: Date() }
  user = Meteor.user()
  now = ts.now()

  console.log 'creating project:', name, description, parentId, user.username
  if ts.isFreelancer user
    return null

  projectId = Projects.insert
    name: name
    description: description
    authorId: user._id
    parent: parentId
    teamId: user.teamId
    createdAt: now

  recipients = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
  content = "#{user.username}创建了项目#{name}"
  Actions.notify recipients, content, content, null
  return projectId

Actions.updateProject = (id, description) ->
  # update project description
  user = Meteor.user()
  project = Projects.findOne _id: id
  recipients = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
  content = "#{user.username}修改了项目#{project.name}的描述"
  Actions.notify recipients, content, content, null
  return ''

Actions.moveProject = (id, newParentId) ->
  # update project parent. need to consider spark project changes
  user = Meteor.user()
  project = Projects.findOne _id: id
  parent = Projects.findOne _id: newParentId
  recipients = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
  content = "#{user.username}修改了项目#{project.name}的上级项目为#{parent.name}"
  Actions.notify recipients, content, content, null
  return ''

Actions.removeProject = (id) ->
  user = Meteor.user()
  project = Projects.findOne _id: id
  if not project?.parent and Sparks.find(projects:id).count() is 0
    Projects.remove id

    recipients = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
    content = "#{user.username}删除了项目#{project.name}"
    Actions.notify recipients, content, content, null

Actions.updateProjectStat = (id, unfinished=1, finished=0, verified=0) ->
  project = Projects.findOne _id: id
  if project
    Projects.update id, $inc: {unfinished: unfinished, finished: finished, verified: verified}

Actions.updateUserStat = (id, submitted=0, unfinished=0, finished=0) ->
  profile = Profiles.findOne userId: id
  if profile
    Profiles.update profile._id, $inc: {totalSubmitted: submitted, totalUnfinished: unfinished, totalFinished: finished}

# sparks related
Actions.createSpark = (title, content, type, projectId, owners, priority, tags, deadlineStr='') ->
  # spark = {
  # _id: uuid, type: 'idea', authorId: userId, auditTrails: [],
  # owners: [userId, ...], finishers: [userId, ...], progress: 10
  # title: 'blabla', content: 'blabla', priority: 1, supporters: [userId1, userId2, ...],
  # finished: false, projects: [projectId, ...], deadline: Date(), createdAt: Date(),
  # updatedAt: Date(), teamId: teamId
  # }
  user = Meteor.user()
  project = Projects.findOne _id: projectId
  if project.parent
    parent = Projects.findOne _id: project.parent
    projects = [project._id, parent._id]
  else
    parent = null
    projects = [project._id]

  if not ts.projects.writable project
    throw new ts.exp.AccessDeniedException('Only team members can add spark to a team project')

  if deadlineStr
    deadline = (new Date(deadlineStr)).getTime()
  else
    deadline = null

  if tags
    _.each tags, (name) ->
      ts.tags.createOrUpdate name, projectId

  now = ts.now()

  team = Teams.findOne user.teamId, fields: {nextIssueId: 1, abbr: 1}
  Teams.update user.teamId, $inc: nextIssueId: 1
  issueId = "#{team.abbr}#{team.nextIssueId}"
  sparkId = Sparks.insert
    type: type
    authorId: user._id
    auditTrails: []
    comments: []
    owners: owners
    progress: 0
    title: title
    content: content
    priority: priority
    supporters: []
    finishers: []
    finished: false
    verified: false
    projects: projects
    deadline: deadline
    createdAt: now
    updatedAt: now
    positionedAt: now
    points: ts.consts.points.FINISH_SPARK
    totalPoints: 0
    teamId: user.teamId
    tags: tags
    issueId: issueId

  sparkType = ts.sparks.type type

  Actions.addPoints ts.consts.points.CREATE_SPARK

  Actions.trackPositioned sparkId
  Actions.updateProjectStat projectId
  Actions.updateUserStat user._id, 1
  _.each owners, (id) ->
    Actions.updateUserStat id, 0, 1

  if owners
    Actions.notify owners, "#{user.username}创建了新#{sparkType.name}: #{issueId}", "#{user.username}创建了新#{sparkType.name}: #{title}: ", sparkId

Actions.createComment = (sparkId, content) ->
  # comments = {_id: uuid(), authorId: userId, content: content}
  if not content
    throw new ts.exp.InvalidValueException 'comment cannot be empty'

  spark = Sparks.findOne _id: sparkId
  if not ts.sparks.writable spark
    throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

  now = ts.now()
  user = Meteor.user()

  comment =
    _id: Meteor.uuid()
    authorId: user._id
    content: content
    createdAt: now

  Sparks.update sparkId, $push: comments: comment
  Actions.addPoints ts.consts.points.COMMENT

  recipients = _.union [spark.authorId], spark.owners, _.pluck(spark.comments, 'authorId')
  Actions.notify recipients, "#{user.username}评论了#{spark.title}", "#{user.username}评论道: #{content}.", sparkId


Actions.supportSpark = (sparkId) ->
  spark = Sparks.findOne _id: sparkId
  if not ts.sparks.writable spark
    throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

  user = Meteor.user()

  if ts.sparks.hasSupported spark
    Sparks.update sparkId, $pull: {supporters: user._id}, $inc: {totalSupporters: -1}
    content = "#{user.username} 取消支持 #{spark.title}"
    Actions.addPoints -1 * ts.consts.points.SUPPORT
  else
    content = "#{user.username} 支持 #{spark.title}"
    Sparks.update sparkId, $push: {supporters: user._id}, $inc: {totalSupporters: 1}
    Actions.addPoints ts.consts.points.SUPPORT

    # TODO: later we should delete notification once user unsupport it.
    recipient = [spark.authorId]
    Actions.notify recipient, "#{user.username}支持了#{spark.title}", content, sparkId


Actions.finishSpark = (sparkId) ->
  spark = Sparks.findOne _id: sparkId
  if not ts.sparks.writable spark
    throw new ts.exp.AccessDeniedException 'Only team members can finish a spark'

  user = Meteor.user()

  if spark.owners[0]
    if spark.owners[0] isnt user._id
      throw new ts.exp.AccessDeniedException 'Only current owner can finish the spark'
  else
    if spark.finishers and not spark.finished
      # fix spark not finished issue
      Sparks.update sparkId, $set: {finished: true}
      return
    else
      throw new ts.exp.AccessDeniedException 'Spark already finished or not assigned yet'

  audit =
    _id: Meteor.uuid()
    authorId: user._id
    createdAt: ts.now()

  currentId = spark.owners[0]
  finishers = spark.finishers
  if spark.owners[1]
    nextId = spark.owners[1]
    nextOwner = Meteor.users.findOne _id: nextId
    audit.content = "#{user.username} 标记自己的工作已完成，转入下一个责任人: #{nextOwner.username}"
    content1 = "#{user.username} 对 #{spark.title} 标记自己的工作已完成，转入下一个责任人: #{nextOwner.username}"
    finished = false
  else
    audit.content = "#{user.username} 将任务标记为完成"
    content1 = "#{user.username} 将任务 #{spark.title} 标记为完成"
    finished = true

  Sparks.update sparkId,
    $set: {finished: finished, points: ts.consts.points.FINISH_SPARK, finishedAt: ts.now()} # restore points after one finished her job
    $pull: {owners: currentId}
    $push: {auditTrails: audit}
    $addToSet: {finishers: currentId}
    $inc: {totalPoints: spark.points}


  if finished
    Actions.updateProjectStat spark.projects[0], -1, 1

  Actions.updateUserStat user._id, 0, -1, 1

  if not finishers or currentId not in finishers
    Actions.addPoints spark.points

  recipients = _.union [spark.authorId], spark.owners
  Actions.notify recipients, "#{user.username}完成了#{spark.title}", audit.content, sparkId

  if finished
    Actions.trackFinished sparkId

Actions.verifySpark = (sparkId) ->
  spark = Sparks.findOne _id: sparkId
  user = Meteor.user()
  if spark.authorId isnt user._id
    throw new ts.exp.AccessDeniedException 'Only owner can verify a spark'

  audit =
    _id: Meteor.uuid()
    authorId: user._id
    createdAt: ts.now()
    content: "#{user.username} 将任务标记为验收合格"

  Sparks.update sparkId,
    $set: {verified: true, updatedAt: ts.now()}
    $push: {auditTrails: audit}

  Actions.updateProjectStat spark.projects[0], 0, -1, 1
  Actions.addPoints 4

Actions.uploadFiles = (sparkId, lists) ->
  # [{"url":"https://www.filepicker.io/api/file/ODrP2zTwTGig5y0RvZyU","filename":"test.pdf","mimetype":"application/pdf","size":50551,"isWriteable":true}]
  #console.log 'update sparks:', sparkId, lists
  if lists.length <= 0
    return

  spark = Sparks.findOne _id: sparkId
  if not ts.sparks.writable spark
    throw new ts.exp.AccessDeniedException 'Only team members can upload files to a spark'

  user = Meteor.user()

  audit =
    _id: Meteor.uuid()
    authorId: user._id
    createdAt: ts.now()
    content: "#{user.username} 上传了"

  content1 = "#{user.username} 在 #{spark.title} 里上传了"

  images = []
  files  = []

  for file in lists
    if file.mimetype.indexOf('image') >= 0
      images.push file
    else
      files.push file

  command = {}
  if files.length > 0
    command.files = files
    filenames = _.pluck(files, 'filename').join(' ')
    desc = " #{files.length}个文件: #{filenames}"
    audit.content += desc
    content1 += desc

  if images.length > 0
    command.images = images
    filenames = _.pluck(images, 'filename').join(' ')
    desc = " #{images.length}个图片: #{filenames}"
    audit.content += desc
    content1 += desc

  #console.log 'command:', command
  Sparks.update sparkId, $pushAll: command, $push: {auditTrails: audit}, $set: {updatedAt: ts.now()}

  recipients = _.union [spark.authorId], spark.owners
  Actions.notify recipients, "#{user.username}在#{spark.title}里上传了新的文件", audit.content, sparkId

Actions.updateSpark = (sparkId, value, field) ->
  formatValue = ->
    switch field
      when 'deadline' then (new Date(value)).getTime()
      when 'priority', 'points' then parseInt value
      else value

  auditInfo = ->
    v = formatValue()
    switch field
      when 'deadline' then "截止日期为: #{ts.formatDate(v)}"
      when 'priority' then "优先级为: #{v}"
      when 'points' then "积分为: #{v}"
      when 'title' then "标题为: #{v}"
      when 'content' then "内容为: #{v}"
      when 'type' then "类型为: #{ts.sparks.type(v).name}"

  #console.log 'updateSpark: ', value, field
  fields = ['project', 'deadline', 'priority', 'owners', 'title', 'content', 'type', 'points']
  if not _.find(fields, (item) -> item is field)
    return


  command = {updatedAt: ts.now()}

  spark = Sparks.findOne _id: sparkId
  if not ts.sparks.writable spark
    throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

  user = Meteor.user()

  audit =
    _id: Meteor.uuid()
    authorId: user._id
    createdAt: ts.now()
    content: "#{user.username} 更新了"

  content1 = "#{user.username} 更新了 #{spark.title} 的"

  if field is 'project'
    if spark.finished
      # finished spark cannot be moved
      return
    project = Projects.findOne _id: value
    if project.parent
      parent = Projects.findOne _id: project.parent
      projects = [project._id, parent._id]
    else
      projects = [project._id]

    info = "项目为: #{project.name}"
    audit.content += info
    content1 += info

    command['projects'] = projects
    command['positionedAt'] = ts.now()
    Actions.trackPositioned spark, -1
    Actions.updateProjectStat spark.projects[0], -1
    Sparks.update sparkId, $set: command, $push: {auditTrails: audit}
    Actions.trackPositioned sparkId, 1
    Actions.updateProjectStat projects[0], 1
  else if field is 'owners'
    users = Meteor.users.find({_id: $in: value}, {fields: {'_id':1, 'username':1}}).fetch()
    #console.log 'new users:', users
    command['owners'] = value

    if value.length > 0
      # if owners updated, spark should be changed back to unfinished
      command['finished'] = false
      command['verified'] = false

    if users
      info = '责任人为: ' + _.pluck(users, 'username').join(', ')
    else
      info = '责任人为空'
    audit.content += info
    content1 += info

    Sparks.update sparkId, $set: command, $push: {auditTrails: audit}
    if spark.finished and command['finished'] is false
      if spark.verified
        Actions.updateProjectStat spark.projects[0], 1, 0, -1
      else
        Actions.updateProjectStat spark.projects[0], 1, -1

    console.log 'update:', command['owners'], spark.owners
    added = _.difference command['owners'], spark.owners
    deleted = _.difference spark.owners, command['owners']

    console.log 'update:', added, deleted
    _.each added, (id) ->
      Actions.updateUserStat id, 0, 1

    _.each deleted, (id) ->
      Actions.updateUserStat id, 0, -1

  else
    info = auditInfo()
    audit.content += info
    # for system audit, do not need to put entire change into it
    if field is 'content'
      content1 += '内容'
    else
      content1 += info

    command[field] = formatValue()
    Sparks.update sparkId, $set: command, $push: {auditTrails: audit}

  recipients = _.union [spark.authorId], spark.owners

  if field is 'points'
    if command[field] > ts.consts.points.FINISH_SPARK and command[field] > spark.points
      # ugly guy we will notify the entire team
      all = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
      recipients = _.without all, user._id
      title = "#{user.username}贱贱地修改了#{spark.title}的积分为#{command[field]}"
    else if command[field] < ts.consts.points.FINISH_SPARK and command[field] < spark.points
      # ugly guy we will notify the entire team
      all = _.pluck Meteor.users.find(teamId: user.teamId).fetch(), '_id'
      recipients = _.without all, user._id
      title = "#{user.username}很有节操地修改了#{spark.title}的积分为#{command[field]}"
    else
      title = "#{user.username}修改了#{spark.title}"
  else
    title = "#{user.username}修改了#{spark.title}"

  Actions.notify recipients, title, audit.content, sparkId

Actions.tagSpark = (sparkId, tags) ->
  spark = Sparks.findOne _id: sparkId
  if not ts.sparks.writable spark
    throw new ts.exp.AccessDeniedException 'Only team members can tag a spark'

  user = Meteor.user()

  tags = tags.split(';')
  added = _.difference tags, spark.tags
  deleted = _.difference spark.tags, tags

  if not added and not deleted
    return

  info = []

  # always use parent project id
  if spark.projects.length > 1
    projectId = spark.projects[1]
  else
    projectId = spark.projects[0]

  if added.length > 0
    _.each added, (name) ->
      ts.tags.createOrUpdate name, projectId
    info.push "添加了标签: #{added.join(', ')}"

  if deleted.length > 0
    info.push "删除了标签: #{deleted.join(', ')}"
    _.each deleted, (name) ->
      ts.tags.createOrUpdate name, projectId, -1


  info = info.join('; ')


  audit =
    _id: Meteor.uuid()
    authorId: user._id
    createdAt: ts.now()
    content: "#{user.username}#{info}"

  content1 = "#{user.username}为#{spark.title}#{info}"

  Sparks.update sparkId,
    $set: {tags: tags}
    $push: {auditTrails: audit}

  recipients = _.union [spark.authorId], spark.owners
  Actions.notify recipients, "#{user.username}修改了#{spark.title}的标签", audit.content, sparkId

# Notifications related
Actions.notify = (recipients, title, content, sparkId, type=1, level=2) ->
  # notification = {
  # _id: uuid, recipientId: userId, level: 1-5|debug|info|warning|important|urgent
  # type: 1-5 | user | spark | project | team | site
  # title: 'bla', content: 'html bla', sparkId: sparkId, createdAt: new Date(), readAt: new Date(), visitedAt: new Date() }
  if not recipients or not title
    return

  actor = Meteor.userId()
  all = _.without recipients, actor

  if not all
    return

  console.log 'Notify: from ', actor, 'to ', all, " with #{title}, #{content} and sparkId is #{sparkId}"

  _.each all, (id) ->
    Notifications.insert
      actorId: actor
      recipientId: id
      level: level
      type: type
      title: title
      content: content
      sparkId: sparkId
      createdAt: ts.now()

Actions.notificationVisited = (nid) ->
  Notifications.update nid, $set: visitedAt: ts.now()

Actions.notificationRead = (nid) ->
  Notifications.update nid, $set: readAt: ts.now()


# tracking stuff
Actions.trackPositioned = (sparkId, value=1) ->
  if sparkId._id
    spark = sparkId
  else
    spark = Sparks.findOne _id: sparkId

  if not spark?.positionedAt
    throw new Meteor.Error 400, "spark #{spark.title} has not yet been positioned"

  positionedDate = ts.toDate spark.positionedAt

  ts.stats.trackDaySpark spark, positionedDate, 'positioned', value



Actions.trackFinished = (sparkId) ->
  if sparkId._id
    spark = sparkId
  else
    spark = Sparks.findOne _id: sparkId

  if not spark?.finished
    throw new Meteor.Error 400, "spark #{spark.title} has not yet been finished"

  finishedDate = ts.toDate spark.finishedAt
  ts.stats.trackDaySpark spark, finishedDate, 'finished', 1

# Other stuff
Actions.online = (isOnline=true) ->
  if Meteor.userId()
    profile = Profiles.findOne userId: Meteor.userId()
    now = ts.now()
    if profile
      if not isOnline
        # online to offline, calculate the seconds user spent on team spark
        seconds = Math.floor((now - profile.lastActive)/1000)
        if seconds > 900
          # for most cases user do any operation should not exceed 15 mins
          seconds = 900
          Profiles.update {userId: profile.userId}, {$set: {online: isOnline}, $inc: {totalSeconds: seconds}}
      else
        # offline to online, start record time spent
        Profiles.update {userId: profile.userId}, {$set: {online: isOnline, lastActive: now}}
    else
      # TODO: work around. should do this in after user create hook
      user = Meteor.user()
      Profiles.insert
        userId: user._id
        username: user.username
        online: isOnline
        teamId: user.teamId
        totalSeconds: 0