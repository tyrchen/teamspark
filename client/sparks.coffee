# spark = {
# _id: uuid, type: 'idea', authorId: userId, auditTrails: [],
# currentOwnerId: userId, nextStep: 1, owners: [userId, ...], progress: 10
# title: 'blabla', content: 'blabla', priority: 1, supporters: [userId1, userId2, ...],
# finished: false, projects: [projectId, ...], deadline: Date(), createdAt: Date(),
# updatedAt: Date(), teamId: teamId
# }

_.extend Template.sparks,
  sparks: ->

    project = ts.State.filterSelected.get()
    order = ts.State.sparkOrder.get()
    type = ts.State.sparkTypeFilter.get()
    priority = ts.State.sparkPriorityFilter.get()
    author = ts.State.sparkAuthorFilter.get()
    filterType = ts.State.filterType.get()
    owner = ts.State.sparkOwnerFilter.get()
    progress = ts.State.sparkProgressFilter.get()
    finish = ts.State.sparkFinishFilter.get()

    query = []

    if project isnt 'all'
      query.push projects: project

    if type isnt 'all'
      query.push type: type

    if priority isnt 'all'
      query.push priority: priority

    if author isnt 'all'
      query.push authorId: author

    if filterType is 'user'
      query.push owners: Meteor.user()._id

    if owner isnt 'all'
      query.push currentOwnerId: owner

    if progress isnt 'all'
      query.push progress: progress

    if finish
      query.push finished: false

    if order is 'createdAt'
      Sparks.find {$and: query}, {sort: createdAt: -1}
    else
      Sparks.find {$and: query}, {sort: updatedAt: -1}

_.extend Template.spark,
# spark = {
  # _id: uuid, type: 'idea', authorId: userId, auditTrails: [],
  # currentOwnerId: userId, nextStep: 1, owners: [userId, ...], progress: 10
  # title: 'blabla', content: 'blabla', priority: 1, supporters: [userId1, userId2, ...],
  # finished: false, projects: [projectId, ...], deadline: Date(), createdAt: Date(),
  # updatedAt: Date(), teamId: teamId
  # }
  rendered: ->
    console.log 'template spark rendered:', @, $('.edit-type', $(@firstNode))
    $parent = $(@firstNode)
    $('.carousel', $parent).carousel
      interval: false
    $('.carousel .item:first-child', $parent).addClass('active')
    #TODO: projects may change so we need to reset editable for .edit-project
    $('.edit-project', $parent).editable(
      type: 'select'
      value: -> @projectId
      placement: 'right'
      name: 'project'
      pk: null
      source: ->
        projects = {}
        for p in ts.projects.all().fetch()
          projects[p._id] = p.name
        return projects
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      console.log value, sparkId
      if value and sparkId
        Meteor.call 'updateSpark', sparkId, value, 'project'
    )

    $('.edit-type', $parent).editable(
      type: 'select'
      value: -> @sparkType
      placement: 'right'
      name: 'sparktype'
      pk: null
      source: ->
        types = {}
        console.log 'types:', types
        _.each ts.sparks.types(), (item) ->
          types[item.id] = item.name

        return types
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      console.log value, sparkId
      if value and sparkId
        Meteor.call 'updateSpark', sparkId, value, 'type'
    )

    $('.edit-priority', $parent).editable(
      type: 'select'
      source: 1:1, 2:2, 3:3, 4:4, 5:5
      value: -> @priority
      placement: 'right'
      name: 'priority'
      pk: null
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      console.log value, sparkId
      if value and sparkId
        Meteor.call 'updateSpark', sparkId, value, 'priority'
    )

    $('.edit-deadline', $parent).editable(
      type: 'date'
      value: -> moment(@deadline)?.format('YYYY-MM-DD')
      placement: 'right'
      name: 'deadline'
      pk: null
      format: 'yyyy-mm-dd'
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      console.log value, sparkId
      Meteor.call 'updateSpark', sparkId, value, 'deadline'
    )

    $('.edit-owners', $parent).editable(
      type: 'text'
      inputclass: 'span4'
      value: ->
        spark = Sparks.findOne _id: @id
        _.pluck(ts.sparks.allOwners(spark), 'username').join(';')
      placement: 'right'
      name: 'owners'
      pk: null
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
      console.log value, sparkId
      owners = _.map value.split(';'), (username) ->
        user = Meteor.users.findOne {teamId: ts.State.teamId.get(), username: username}, {fields: '_id'}
        return user?._id

      owners = _.filter owners, (id) -> id
      if owners and sparkId
        Meteor.call 'updateSpark', sparkId, owners, 'owners'
    ).on('shown', (e, editable) ->
      console.log e, editable, $(editable.$content).addClass('editable-owners')
      usernames = _.pluck ts.members().fetch(), 'username'

      $(editable.$input).select2
        tags: usernames
        placeholder:'添加责任人'
        tokenSeparators: [' ']
        separator:';'
    )

  events:
    'click .show-comments': (e) ->
      $spark = $(e.currentTarget).closest('.spark')
      $('.comments', $spark).toggle()
      $('.audits', $spark).hide()

    'click .show-audits': (e) ->
      $spark = $(e.currentTarget).closest('.spark')
      $('.audits', $spark).toggle()
      $('.comments', $spark).hide()

    'click .support': (e) ->
      Meteor.call 'supportSpark', @_id

    'click .finish': (e) ->
      Meteor.call 'finishSpark', @_id

    'click .upload': (e) ->
      id = @_id
      filepicker.pickMultiple
        extensions: ['.png', '.jpg', '.gif', '.doc', '.xls', '.ppt', '.docx', '.pptx', '.xlsx', '.pdf', '.txt']
        container: 'modal'
        services: ['COMPUTER']
        (fpfiles) =>
          console.log 'uploaded:', id, fpfiles
          Meteor.call 'uploadFiles', id, fpfiles


    'click .edit': (e) ->
      $node = $('#edit-spark')
      $node.data('id', @_id)
      console.log 'spark id:', $node.data('id'), @title, @content
      $('.modal-header h3', $node).val "编辑 #{@title}"
      $('#spark-edit-title', $node).val @title

      # remove old editor
      editor = ts.editor().panelInstance 'spark-edit-content', hasPanel : true
      editor.removeInstance('spark-edit-content')
      editor = null

      $('#spark-edit-content', $node).html @content

      ts.editor().panelInstance 'spark-edit-content', hasPanel : true

      $('#edit-spark').modal()

    'click .allocate': (e) ->
      alert 'Not finished yet'


  author: ->
    Meteor.users.findOne @authorId

  created: ->
    moment(@createdAt).fromNow()

  updated: ->
    moment(@updatedAt).fromNow()

  expired: ->
    if @deadline
      return moment(@deadline).fromNow()
    return '未指定'

  typeObj: ->
    obj = ts.sparks.type(@)

  activity: ->
    return @title

  project: ->
    if @projects?.length
      return Projects.findOne @projects[0]
    else
      return null

  supported: ->
    found = ts.sparks.hasSupported @
    if found
      return 'supported'
    return ''

  showSupporters: ->
    items = []
    supporters = Meteor.users.find _id: $in: @supporters
    supporters.forEach (item) ->
      items.push "<li><a href='#'><img src='#{item.avatar}' class='avatar-small' title='#{item.username}'/></a></li>"
    return items.join('\n')

  showOwners: ->
    items = []
    owners = _.map @owners, (id) -> Meteor.users.findOne _id: id

    currentOwnerId = @currentOwnerId
    owners.forEach (item) ->
      if currentOwnerId is item._id
        active = 'active'
      else
        active = ''

      items.push "<li class='#{active}'><a href='#'><img src='#{item.avatar}' class='avatar-small' title='#{item.username}'/></a></li>"
    return items.join('\n')

  allocated: ->
    @finished or @currentOwnerId

  nextOwner: ->
    ts.sparks.nextOwner @

  supporttedUsers: ->
    Meteor.users.find _id: $in: @supporters

  urgentStyle: ->
    if ts.sparks.isUrgent @
      return 'urgent'
    return ''

  importantStyle: ->
    if ts.sparks.isImportant @
      return 'important'
    return ''

  finishedStyle: ->
    if @finished
      return 'finished'
    return ''

  info: ->
    typeObj = ts.sparks.type @
    text = [typeObj.name]
    if ts.sparks.isUrgent @
      text.push '紧急(3日内到期)'

    if ts.sparks.isImportant @
      text.push '重要(优先级4及以上)'

    if text.length == 1
      text.push '正常'

    return text.join(' | ')

  reversedComments: ->
    if @comments
      comments = _.clone(@comments)
      comments.reverse()
      return comments
    else
      return []

  reversedAudits: ->
    if @auditTrails
      audits = _.clone(@auditTrails)
      audits.reverse()
      return audits
    else
      return []

  canFinish: ->
    if @finished
      return false

    if not @currentOwnerId
      if ts.isStaff()
        return true
    else if @currentOwnerId is Meteor.user()._id
      return true

    return false

  hasImages: ->
    @images?.length > 0

  hasMoreImages: ->
    @images?.length > 1

  hasFiles: ->
    @files?.length > 0

_.extend Template.commentInput,
  events:
    'click .btn': (e) ->
      $form = $(e.currentTarget).closest('form')
      $node = $form.closest('.comment-box')
      content = $('textarea', $form).val()
      Meteor.call 'createComment', @_id, content, (error, result) ->
        $('textarea', $form).val('')
        Meteor.setTimeout (->
          $node.show()
        ), 200

  avatar: ->
    Meteor.user().avatar

_.extend Template.comment,
  author: ->
    Meteor.users.findOne @authorId

  created: ->
    moment(@createdAt).fromNow()

Meteor.startup ->
  filepicker.setKey 'AJEoTb-YlRYuHGmtOfmdjz'