Meteor.methods
  createSpark: (title, content, type, projectId, owners, priority, deadlineStr='') ->
    # spark = {
    # _id: uuid, type: 'idea', authorId: userId, auditTrails: [], comments: []
    # currentOwnerId: userId, nextStep: 1, owners: [userId, ...], progress: 10
    # title: 'blabla', content: 'blabla', priority: 1, supporters: [userId1, userId2, ...],
    # finished: false, projects: [projectId, ...], deadline: Date(), createdAt: Date(),
    # updatedAt: Date(), teamId: teamId
    # }
    console.log 'createSpark'
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
    AuditTrails.insert
      userId: user._id
      content: "#{user.username}创建了一个#{sparkType.name}: #{title}"
      teamId: user.teamId
      projectId: projectId
      createdAt: ts.now()

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

    console.log sparkId, user._id, content
    Sparks.update sparkId, $push: comments: comment

  supportSpark: (sparkId) ->
    spark = Sparks.findOne _id: sparkId
    if not ts.sparks.writable spark
      throw new ts.exp.AccessDeniedException 'Only team members can add comments to a spark'

    user = Meteor.user()

    if ts.sparks.hasSupported spark
      Sparks.update sparkId, $pull: supporters: user._id
    else
      Sparks.update sparkId, $push: supporters: user._id

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
      Sparks.update sparkId, $set: {currentOwnerId: nextId}, $inc: {nextStep: 1}, $push: {auditTrails: audit}
    else
      audit.content = "#{user.username} 将整个任务标记为完成"
      Sparks.update sparkId, $set: {currentOwnerId: null, finished: true}, $push: {auditTrails: audit}

