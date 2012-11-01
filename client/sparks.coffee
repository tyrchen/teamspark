_.extend Template.sparks,
  sparks: ->
    query = ts.sparks.query()

    order = ts.State.sparkOrder.get()

    sort = {}
    sort[order] = -1

    Sparks.find {$and: query}, {sort: sort}

_.extend Template.spark,
  rendered: ->
    #console.log 'template spark rendered:', @, $('.edit-type', $(@firstNode))
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
      if value and sparkId
        Meteor.call 'updateSpark', sparkId, value, 'project'
    )

    $('.edit-type', $parent).editable(
      type: 'select'
      value: -> @sparkType
      placement: 'right'
      name: 'sparktype'
      pk: null
      source: -> ts.consts.filter.TYPE()
    ).on('render', (e, editable) ->
      value = editable.value
      sparkId = editable.$element.data('id')
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
      Meteor.call 'updateSpark', sparkId, value, 'deadline'
    )

    ts.setEditable
      node: $('.edit-points', $parent)
      value: -> @points
      source: -> ts.consts.points.FINISH_SPARK_POINTS
      renderCallback: (e, editable) ->
        value = editable.value
        sparkId = editable.$element.data('id')
        Meteor.call 'updateSpark', sparkId, value, 'points'

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
      owners = _.map value.split(';'), (username) ->
        user = Meteor.users.findOne {teamId: ts.State.teamId.get(), username: username}, {fields: '_id'}
        return user?._id

      owners = _.filter owners, (id) -> id
      if owners and sparkId
        Meteor.call 'updateSpark', sparkId, owners, 'owners'
    ).on('shown', (e, editable) ->
      #console.log e, editable, $(editable.$content).addClass('editable-owners')
      usernames = _.pluck ts.members.all().fetch(), 'username'

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
        container: 'modal'
        services: ['COMPUTER']
        (fpfiles) =>
          #console.log 'uploaded:', id, fpfiles
          Meteor.call 'uploadFiles', id, fpfiles


    'click .edit': (e) ->
      $node = $('#edit-spark')
      $node.data('id', @_id)
      #console.log 'spark id:', $node.data('id'), @title, @content
      $('.modal-header h3', $node).text "编辑 #{@title}"
      $('#spark-edit-title', $node).val @title

      # remove old editor
      editor = ts.editor().panelInstance 'spark-edit-content', hasPanel : true
      editor.removeInstance('spark-edit-content')
      editor = null

      $('#spark-edit-content', $node).html @content

      ts.editor().panelInstance 'spark-edit-content', hasPanel : true

      $('#edit-spark').modal
        keyboard: false
        backdrop: 'static'

    'click .allocate': (e) ->
      alert 'Not finished yet'


  author: ->
    Meteor.users.findOne @authorId

  created: ->
    moment(@createdAt).fromNow()

  positioned: ->
    moment(@positionedAt).fromNow()

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

    currentId = owners[0]
    owners.forEach (item) ->
      items.push "<li><a href='#'><img src='#{item.avatar}' class='avatar-small' title='#{item.username}'/></a></li>"
    return items.join('\n')

  showFinishers: ->
    items = []
    finishers = _.map @finishers, (id) -> Meteor.users.findOne _id: id
    finishers.forEach (item) ->
      items.push "<li><a href='#'><img src='#{item.avatar}' class='avatar-small' title='#{item.username}'/></a></li>"

    return items.join('\n')

  allocated: ->
    @owners

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

  totalComments: ->
    if @comments
      return @comments.length
    return 0

  reversedComments: ->
    if @comments
      comments = _.clone(@comments)
      comments.reverse()
      return comments
    else
      return []

  totalAudits: ->
    if @auditTrails
      return @auditTrails.length
    return 0

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

    if not @owners[0]
      if ts.isStaff()
        return true
    else if @owners[0] is Meteor.user()._id
      return true

    return false

  hasImages: ->
    @images?.length > 0

  hasMoreImages: ->
    @images?.length > 1

  hasFiles: ->
    @files?.length > 0

  isCurrentOwner: ->
    Meteor.userId() is @owners[0]

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
