Meteor.methods
  createSpark: (title, content, type, projectId, owners, priority, deadlineStr='') ->
    # spark = {
    # _id: uuid, type: 'idea', authorId: userId, auditTrails: [],
    # currentOwnerId: userId, nextStep: 1, owners: [userId, ...], progress: 10
    # title: 'blabla', content: 'blabla', priority: 1, supporters: [userId1, userId2, ...],
    # finished: false, projects: [projectId, ...], deadline: Date(), createdAt: Date(),
    # updatedAt: Date(), teamId: teamId
    # }
    team = ts.currentTeam()
    user = Meteor.user()
    project = Projects.findOne _id: projectId
    if project.parent
      parent = Projects.findOne _id: project.parent
      projects = [project._id, parent._id]
    else
      parent = null
      projects = [project._id]

    if not ts.isTeamProject project, team
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
      teamId: team._id

    sparkType = _.find ts.sparks.types(), (item) -> item.id is type
    AuditTrails.insert
      userId: user._id
      content: "#{user.username}创建了一个#{sparkType.name}: #{title}"
      teamId: team._id
      projectId: projectId
      createdAt: ts.now()