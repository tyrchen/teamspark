# project = { _id: uuid, name: 'cayman', description: 'cayman is a project', authorId: null, parentId: null, teamId: teamId, createdAt: Date() }

ts = ts || {}

ts.setFinish = -> ts.State.sparkFinishFilter.set {id: 2, name: '已完成'}
ts.setUnfinish = -> ts.State.sparkFinishFilter.set {id: 1, name: '未完成'}
ts.setVerify = -> ts.State.sparkVerifyFilter.set {id: 2, name: '已验证'}
ts.setUnverify = -> ts.State.sparkVerifyFilter.set {id: 1, name: '未验证'}
ts.setAuthor = ->
  user = Meteor.user()
  ts.State.sparkAuthorFilter.set {id: user._id, name: user.username}

_.extend Template.projects,
  rendered: ->
    $node = $('#select-project')
    $node.val ts.State.filterSelected.getName()
    ts.setUnfinish()
    #$node.select2()

  events:
    'click #filter-team': (e) ->
      ts.State.filterType.set 'team'

    'click #filter-member': (e) ->
      ts.State.filterType.set 'user'

    'click .shortcut': (e) ->
      $('.shortcut').parent().removeClass('active')
      $node = $(e.currentTarget)
      type = $node.data('type')
      $node.parent().addClass('active')
      ts.State.filterShortcut.set type

      ts.State.clearFilters()
      switch type
        when 'finished'
          ts.setFinish()
          ts.setUnverify()
        when 'unfinished' then setUnfinish()
        when 'important'
          ts.setUnfinish()
          ts.State.sparkPriorityFilter.set {id: 4, name: 4}
        when 'urgent'
          ts.setUnfinish()
          ts.State.sparkDeadlineFilter.set {id: ts.consts.EXPIRE_IN_3_DAYS, name: 1}
        when 'verified'
          ts.setFinish()
          ts.setVerify()
        when 'my-finished'
          ts.setFinish()
          ts.setUnverify()
          ts.setAuthor()
        when 'my-unfinished'
          ts.setUnfinish()
          ts.setAuthor()
        when 'my-verified'
          ts.setFinish()
          ts.setVerify()
          ts.setAuthor()


    'change #select-project': (e) ->
      # TODO: fix me. this is a workaround to clear notification entry and show sparks
      name = $(e.currentTarget).val()
      if name is 'new'
        $('#add-project-dialog').modal()
        $(e.currentTarget).val ts.State.filterSelected.getName()
        return

      ts.State.showSpark.set null
      ts.State.clearFilters()
      Router.setProject name


    'click #add-project-submit': (e) ->
      $form = $('#add-project-dialog form')
      $name = $('input[name="name"]', $form)
      name = $name.val()
      description = $('textarea[name="description"]', $form).val()
      parentId = $('select[name="parent"]', $form).val()
      if parentId is 'null'
        parentId = null
      #console.log "name: #{name}, desc: #{description}, parent: #{parentId}"
      count = Projects.find({name: name, teamId: Meteor.user().teamId}).count()

      if not name or count > 0
        $name.parent().addClass 'error'
        return null

      Meteor.call 'createProject', name, description, parentId, (error, result) ->
        $('.control-group', $form).removeClass 'error'
        $form[0].reset()
        $('#add-project-dialog').modal 'hide'

    'click #add-project-cancel': (e) ->
      $('#add-project-dialog form .control-group').removeClass 'error'
      $('#add-project-dialog').modal 'hide'

  isActiveMember: ->
    if ts.filteringUser()
      return 'active'
    return ''

  isActiveTeam: ->
    if ts.filteringTeam()
      return 'active'
    return ''

  isFilterSelected: (id='all') ->
    if ts.State.filterSelected.get() is id
      return 'active'
    return ''

  parentProjects: ->
    projects = ts.projects.parents().fetch()
    #_.sortBy projects, (item) -> -Template.projects.totalSparks(item._id, true)

  childProjects: (id)->
    projects = ts.projects.children(id).fetch()
    #_.sortBy projects, (item) -> -Template.projects.totalSparks(item._id)

  taskName: ->
    if ts.filteringUser()
      return '我的任务'
    return '团队任务'

  getQuery: ->
    query = []
    p = Projects.findOne _id: ts.State.filterSelected.get()
    if p?.parent
      query.push projects: p._id
    else
      query.push projects: [p._id]
    return query

  totalUnfinished: ->
    query = Template.projects.getQuery()
    query.push(finished: false)
    if ts.filteringUser()
      query.push(owners: Meteor.userId())
    Sparks.find($and: query).count()

  totalImportant: ->
    query = Template.projects.getQuery()
    query.push({finished: false}, {priority: $gte: 4})
    if ts.filteringUser()
      query.push(owners: Meteor.userId())
    Sparks.find($and: query).count()

  totalUrgent: ->
    query = Template.projects.getQuery()
    query.push({finished: false}, {deadline: {$gt: ts.now(), $lte: ts.consts.EXPIRE_IN_3_DAYS + ts.now()}})
    if ts.filteringUser()
      query.push(owners: Meteor.userId())
    Sparks.find($and: query).count()

  totalFinished: ->
    query = Template.projects.getQuery()
    if ts.filteringUser()
      query.push({finishers: Meteor.userId()}, {verified: false})
    else
      query.push({finished: true}, {verified: false})
    Sparks.find($and: query).count()

  totalVerified: ->
    query = Template.projects.getQuery()
    query.push({verified: true}, {finished: true})
    if ts.filteringUser()
      query.push(finishers: Meteor.userId())
    Sparks.find($and: query).count()

  totalMyUnfinished: ->
    query = Template.projects.getQuery()
    query.push({finished: false}, {authorId: Meteor.userId()})
    Sparks.find($and: query).count()

  totalMyFinished: ->
    query = Template.projects.getQuery()
    query.push({finished: true}, {verified: false}, {authorId: Meteor.userId()})
    Sparks.find($and: query).count()

  totalMyVerified: ->
    query = Template.projects.getQuery()
    query.push({finished: true}, {verified: true}, {authorId: Meteor.userId()})
    Sparks.find($and: query).count()

