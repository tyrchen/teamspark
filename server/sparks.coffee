Meteor.methods
  createSpark: (title, content, type, projectId, owners, priority, deadlineStr='') ->
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

    now = ts.now()

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
      projects: projects
      deadline: deadline
      createdAt: now
      updatedAt: now
      positionedAt: now
      points: ts.consts.points.FINISH_SPARK
      totalPoints: 0
      teamId: user.teamId

    sparkType = ts.sparks.type type

    Meteor.call 'createAudit', "#{user.username}创建了一个#{sparkType.name}: #{title}", projectId
    Meteor.call 'addPoints', ts.consts.points.CREATE_SPARK
    Meteor.call 'trackPositioned', sparkId

    if owners
      Meteor.call 'notify', owners, "#{user.username}创建了新#{sparkType.name}", "#{user.username}创建了新#{sparkType.name}: #{title}: ", sparkId

  createComment: (sparkId, content) ->
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
    Meteor.call 'addPoints', ts.consts.points.COMMENT

    recipients = _.union [spark.authorId], spark.owners, _.pluck(spark.comments, 'authorId')
    Meteor.call 'notify', recipients, "#{user.username}评论了#{spark.title}", "#{user.username}评论道: #{content}.", sparkId


  supportSpark: (sparkId) ->
    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

    user = Meteor.user()

    if ts.sparks.hasSupported spark
      Sparks.update sparkId, $pull: {supporters: user._id}, $inc: {totalSupporters: -1}
      content = "#{user.username} 取消支持 #{spark.title}"
      Meteor.call 'addPoints', -1 * ts.consts.points.SUPPORT
    else
      content = "#{user.username} 支持 #{spark.title}"
      Sparks.update sparkId, $push: {supporters: user._id}, $inc: {totalSupporters: 1}
      Meteor.call 'addPoints', ts.consts.points.SUPPORT

      # TODO: later we should delete notification once user unsupport it.
      recipient = [spark.authorId]
      Meteor.call 'notify', recipient, "#{user.username}支持了#{spark.title}", content, sparkId

    #Meteor.call 'createAudit', content, projectId



  finishSpark: (sparkId) ->
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


    Meteor.call 'createAudit', content1, spark.projects[0]

    if not finishers or currentId not in finishers
      Meteor.call 'addPoints', spark.points

    recipients = _.union [spark.authorId], spark.owners
    Meteor.call 'notify', recipients, "#{user.username}完成了#{spark.title}", audit.content, sparkId

    if finished
      Meteor.call 'trackFinished', sparkId

  uploadFiles: (sparkId, lists) ->
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

    Meteor.call 'createAudit', content1, spark.projects[0]

    recipients = _.union [spark.authorId], spark.owners
    Meteor.call 'notify', recipients, "#{user.username}在#{spark.title}里上传了新的文件", audit.content, sparkId

  updateSpark: (sparkId, value, field) ->
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
      Meteor.call 'trackPositioned', spark, -1
      Sparks.update sparkId, $set: command, $push: {auditTrails: audit}
      Meteor.call 'trackPositioned', sparkId, 1
    else if field is 'owners'
      users = Meteor.users.find({_id: $in: value}, {fields: {'_id':1, 'username':1}}).fetch()
      #console.log 'new users:', users
      command['owners'] = value

      if value.length > 0
        # if owners updated, spark should be changed back to unfinished
        command['finished'] = false

      if users
        info = '责任人为: ' + _.pluck(users, 'username').join(', ')
      else
        info = '责任人为空'
      audit.content += info
      content1 += info

      Sparks.update sparkId, $set: command, $push: {auditTrails: audit}
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

    Meteor.call 'createAudit', content1, spark.projects[0]

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

    Meteor.call 'notify', recipients, title, audit.content, sparkId

  tagSpark: (sparkId, tags) ->
    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can tag a spark'

    user = Meteor.user()

    tags = tags.split(';')
    added = _.difference tags, spark.tags
    deleted = _.difference spark.tags, tags

    console.log "added: #{added}, deleted: #{deleted}"
    if not added and not deleted
      return

    info = []
    if added.length > 0
      _.each added, (name) ->
        # always use parent project id
        if spark.projects.length > 1
          projectId = spark.projects[1]
        else
          projectId = spark.projects[0]

        tag = Tags.findOne {name: name, teamId: user.teamId, projectId: projectId}
        if tag
          Tags.update tag._id, $inc: sparks: 1
        else
          Tags.insert
            name: name
            teamId: user.teamId
            projectId: projectId
            createdAt: ts.now()
            sparks: 1
      info.push "添加了标签: #{added.join(', ')}"

    if deleted.length > 0
      info.push "删除了标签: #{deleted.join(', ')}"
      _.each deleted, (name) ->
        Tags.update {name: name, teamId: user.teamId}, {$inc: sparks: -1}


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

    Meteor.call 'createAudit', content1, spark.projects[0]

    recipients = _.union [spark.authorId], spark.owners
    Meteor.call 'notify', recipients, "#{user.username}修改了#{spark.title}的标签", audit.content, sparkId