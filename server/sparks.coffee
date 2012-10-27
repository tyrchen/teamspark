Meteor.methods
  createSpark: (title, content, type, projectId, owners, priority, deadlineStr='') ->
    # spark = {
    # _id: uuid, type: 'idea', authorId: userId, auditTrails: [], comments: []
    # currentOwnerId: userId, nextStep: 1, owners: [userId, ...], progress: 10
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

    if owners.length > 0
      currentOwnerId = owners[0]
      nextStep = 1
    else
      currentOwnerId = null
      nextStep = 0

    if deadlineStr
      deadline = (new Date(deadlineStr)).getTime()
    else
      deadline = null

    now = ts.now()

    Sparks.insert
      type: type
      authorId: user._id
      auditTrails: []
      comments: []
      currentOwnerId: currentOwnerId
      nextStep: nextStep
      owners: owners
      progress: 0
      title: title
      content: content
      priority: priority
      supporters: []
      finished: false
      projects: projects
      deadline: deadline
      createdAt: now
      updatedAt: now
      teamId: user.teamId

    sparkType = _.find ts.sparks.types(), (item) -> item.id is type

    Meteor.call 'createAudit', "#{user.username}创建了一个#{sparkType.name}: #{title}", projectId
    Meteor.call 'addPoints', ts.consts.points.CREATE_SPARK

  createComment: (sparkId, content) ->
    # comments = {_id: uuid(), authorId: userId, content: content}
    if not content
      throw new ts.exp.InvalidValueException 'comment cannot be empty'

    if not ts.sparks.writable sparkId
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

  supportSpark: (sparkId) ->
    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

    user = Meteor.user()

    if ts.sparks.hasSupported spark
      Sparks.update sparkId, $pull: supporters: user._id
      #content = "#{user.username} 取消支持 #{spark.title}"
      Meteor.call 'addPoints', -1 * ts.consts.points.SUPPORT
    else
      #content = "#{user.username} 支持 #{spark.title}"
      Sparks.update sparkId, $push: supporters: user._id
      Meteor.call 'addPoints', ts.consts.points.SUPPORT

    #Meteor.call 'createAudit', content, projectId

  finishSpark: (sparkId) ->
    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

    user = Meteor.user()

    if spark.currentOwnerId
      if spark.currentOwnerId isnt user._id
        throw new ts.exp.AccessDeniedException 'Only current owner can finish the spark'

    audit =
      _id: Meteor.uuid()
      authorId: user._id
      createdAt: ts.now()

    if spark.currentOwnerId and spark.owners.length - 1 >= spark.nextStep
      nextId = spark.owners[spark.nextStep]
      nextOwner = Meteor.users.findOne _id: nextId
      audit.content = "#{user.username} 标记自己的工作已完成，转入下一个责任人: #{nextOwner.username}"
      content1 = "#{user.username} 对 #{spark.title} 标记自己的工作已完成，转入下一个责任人: #{nextOwner.username}"
      Sparks.update sparkId, $set: {currentOwnerId: nextId}, $inc: {nextStep: 1}, $push: {auditTrails: audit}
    else
      audit.content = "#{user.username} 将任务标记为完成"
      content1 = "#{user.username} 将任务 #{spark.title} 标记为完成"
      Sparks.update sparkId, $set: {currentOwnerId: null, finished: true}, $push: {auditTrails: audit}


    Meteor.call 'createAudit', content1, spark.projects[0]
    Meteor.call 'addPoints', ts.consts.points.FINISH_SPARK

  uploadFiles: (sparkId, lists) ->
    # [{"url":"https://www.filepicker.io/api/file/ODrP2zTwTGig5y0RvZyU","filename":"test.pdf","mimetype":"application/pdf","size":50551,"isWriteable":true}]
    #console.log 'update sparks:', sparkId, lists
    if lists.length <= 0
      return

    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

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

  updateSpark: (sparkId, value, field) ->
    formatValue = ->
      switch field
        when 'deadline' then new Date(value)
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
      if not _.find(value, (id) -> spark.currentOwnerId is id)
        if value.length > 0
          command['currentOwnerId'] = value[0]
        else
          command['currentOwnerId'] = null

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