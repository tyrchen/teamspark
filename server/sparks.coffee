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
      teamId: user.teamId

    sparkType = ts.sparks.type type

    Meteor.call 'createAudit', "#{user.username}创建了一个#{sparkType.name}: #{title}", projectId
    Meteor.call 'addPoints', ts.consts.points.CREATE_SPARK

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

    sparkType = ts.sparks.type spark

    comment =
      _id: Meteor.uuid()
      authorId: user._id
      content: content
      createdAt: now

    Sparks.update sparkId, $push: comments: comment
    Meteor.call 'addPoints', ts.consts.points.COMMENT

    recipients = _.union [spark.authorId], spark.owners, _.pluck(spark.comments, 'authorId')
    Meteor.call 'notify', recipients, "#{sparkType.name}#{spark.title}有了新评论", "#{user.username}评论道: #{content}. 详细信息: ", sparkId


  supportSpark: (sparkId) ->
    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

    user = Meteor.user()
    sparkType = ts.sparks.type spark

    if ts.sparks.hasSupported spark
      Sparks.update sparkId, $pull: supporters: user._id
      content = "#{user.username} 取消支持 #{spark.title}"
      Meteor.call 'addPoints', -1 * ts.consts.points.SUPPORT
    else
      content = "#{user.username} 支持 #{spark.title}"
      Sparks.update sparkId, $push: supporters: user._id
      Meteor.call 'addPoints', ts.consts.points.SUPPORT

      # TODO: later we should delete notification once user unsupport it.
      recipient = spark.authorId
      Meteor.call 'notify', recipient, "#{sparkType.name}#{spark.title}有了新的支持者", content, sparkId

    #Meteor.call 'createAudit', content, projectId



  finishSpark: (sparkId) ->
    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

    user = Meteor.user()
    sparkType = ts.sparks.type spark

    if spark.owners[0]
      if spark.owners[0] isnt user._id
        throw new ts.exp.AccessDeniedException 'Only current owner can finish the spark'
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
    else
      audit.content = "#{user.username} 将任务标记为完成"
      content1 = "#{user.username} 将任务 #{spark.title} 标记为完成"

    Sparks.update sparkId, $pull: {owners: currentId}, $push: {auditTrails: audit}, $addToSet: {finishers: currentId}


    Meteor.call 'createAudit', content1, spark.projects[0]

    if finishers and currentId not in finishers
      Meteor.call 'addPoints', ts.consts.points.FINISH_SPARK

    recipients = _.union [spark.authorId], spark.owners
    Meteor.call 'notify', recipients, "#{sparkType.name}#{spark.title}被完成", audit.content, sparkId

  uploadFiles: (sparkId, lists) ->
    # [{"url":"https://www.filepicker.io/api/file/ODrP2zTwTGig5y0RvZyU","filename":"test.pdf","mimetype":"application/pdf","size":50551,"isWriteable":true}]
    #console.log 'update sparks:', sparkId, lists
    if lists.length <= 0
      return

    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

    user = Meteor.user()
    sparkType = ts.sparks.type spark

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
    Meteor.call 'notify', recipients, "#{sparkType.name}#{spark.title}有了新的文件", audit.content, sparkId

  updateSpark: (sparkId, value, field) ->
    formatValue = ->
      switch field
        when 'deadline' then (new Date(value)).getTime()
        when 'priority' then parseInt value
        else value

    auditInfo = ->
      v = formatValue()
      switch field
        when 'deadline' then "截止日期为: #{ts.formatDate(v)}"
        when 'priority' then "优先级为: #{v}"
        when 'title' then "标题为: #{v}"
        when 'content' then "内容为: #{v}"
        when 'type' then "类型为: #{ts.sparks.type(v).name}"

    #console.log 'updateSpark: ', value, field
    fields = ['project', 'deadline', 'priority', 'owners', 'title', 'content', 'type']
    if not _.find(fields, (item) -> item is field)
      return


    command = {updatedAt: ts.now()}

    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

    user = Meteor.user()
    sparkType = ts.sparks.type spark

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
      Sparks.update sparkId, $set: command, $push: {auditTrails: audit}
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
    Meteor.call 'notify', recipients, "#{sparkType.name}#{spark.title}被修改", audit.content, sparkId