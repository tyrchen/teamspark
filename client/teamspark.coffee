ts = ts || {}
ts.filteringTeam = ->
  ts.State.filterType.get() is 'team'

ts.filteringUser = ->
  ts.State.filterType.get() is 'user'

ts.filteringProject = ->
  ts.State.filterSelected.get() isnt 'all'

ts.select2 = ts.select2 || {}
ts.select2.formatSpark = (item) ->
  author = Meteor.users.findOne(_id:item.authorId)
  if author
    authorNode = "<div class='pull-left'><img class='avatar' src='#{author.avatar}'/></div>"
    createdNode = "<span class='created'>#{moment(item.createdAt).fromNow()}</span>"
    createClass = ''
  else
    authorNode = ''
    createdNode = ''
    createClass = 'new'

  tags = _.map item.tags, (tag) -> "<span class='label label-info'>#{tag}</span>"
  if tags
    tags = tags.join('')
  else
    tags = ''

  content = "<p class='content clearfix'>#{item.content}</p>"
  return "<div class='spark-search-item #{createClass}'> #{authorNode}<div> <span class='title'>#{item.issueId}: #{item.text}</span> #{tags} #{createdNode}#{content}</div></div>"

ts.stripTags = (content) ->
  if content
    return content.replace(/(<([^>]+)>)/ig,"")
  return ''

ts.select2.formatSparkSelection = (item) ->
  console.log item, item._id
  return item._id

# TODO: this is not a perfect solution, however using jquery .on cannot bind the click event on these anchors which are created on the fly.
ts.createSparkFunc = (id) ->
  $('#search-spark').select2('close')
  type = _.find Template.sparkFilter.types(), (item) -> item.id is id
  ts.State.sparkToCreate.set {id: id, name: type.name}
  $('#add-spark').modal
    keyboard: false
    backdrop: 'static'

_.extend Template.content,
  events:
    'click #manage-member': (e) ->
      $('#manage-member-dialog').modal
        keyboard: false
        backdrop: 'static'
      $node = $('#member-name')
      $node.typeahead
        minLength: 2
        display: 'username'
        source: (query) ->
          items = Meteor.users.find($and: [
            username:
              $regex : query
              $options: 'i'
            teamId: null
          ]).fetch()

          _.map items, (item) ->
            id: item._id
            username: item.username
            avatar: item.avatar
            toLowerCase: -> @username.toLowerCase()
            toString: -> JSON.stringify @
            indexOf: (string) -> String.prototype.indexOf.apply @username, arguments
            replace: (string) -> String.prototype.replace.apply @username, arguments

        updater: (itemString) ->
          item = JSON.parse itemString
          $member = $("<li data-id='#{item.id}' class='added'><img class='avatar' src='#{item.avatar}' alt='#{item.username}' /></li>")
          $member.appendTo $('#existing-members')
          return ''

    'click #existing-members li': (e) ->
      if this._id is ts.currentTeam().authorId
        return

      $this = $(e.currentTarget)
      if $this.hasClass 'mask'
        $this.removeClass 'mask'
      else
        $this.addClass 'mask'

    'click #manage-member-cancel': (e) ->
      $('#manage-member-dialog').modal 'hide'

    'click #manage-member-submit': (e) ->
      $added = $('#existing-members li.added:not(.mask)')
      $removed = $('#existing-members li.mask:not(.added)')
      added_ids = []
      removed_ids = []
      added_ids = _.map $added, (item) -> $(item).data('id')
      removed_ids = _.map $removed, (item) -> $(item).data('id')
      Actions.updateMembers added_ids, removed_ids
      $('#manage-member-dialog').modal 'hide'


    'click #logout': (e) ->
      Meteor.logout()

    'click #spark-board': (e) ->
      e.preventDefault()

      name = ts.State.filterSelected.getName()
      ts.State.showContent.set 'sparks'
      Router.setProject name

    'click #schedule-board': (e) ->
      e.preventDefault()

      name = ts.State.filterSelected.getName()
      ts.State.showContent.set 'schedule'
      Router.setProject name

    'click #chart-board': (e) ->
      e.preventDefault()

      name = ts.State.filterSelected.getName()
      ts.State.showContent.set 'charts'
      Router.setProject name

  loggedIn: -> Meteor.userId()
  projects: -> Projects.find()
  teamName: -> ts.currentTeam()?.name
  isOrphan: ->
    if Meteor.userId() and not Meteor.user().teamId
      return 'orphan'
    return ''

  configureTeam: ->
    Teams.find().count() is 0

  showSingleSpark: ->
    ts.State.showSpark.get()

  singleSpark: ->
    s = ts.State.showSpark.get()
    Sparks.findOne _id: s._id

  showSparks: ->
    if ts.State.showContent.get() is 'sparks'
      return 'active'
    return ''

  showSchedule: ->
    if ts.State.showContent.get() is 'schedule'
      return 'active'
    return ''

  showCharts: ->
    if ts.State.showContent.get() is 'charts'
      return 'active'
    return ''


_.extend Template.login,
  events:
    'click #login-buttons-weibo': (e) ->
      Meteor.loginWithWeibo()

    'click #login-buttons-github': (e) ->
      Meteor.loginWithGithub()

    'click #login-buttons-google': (e) ->
      Meteor.loginWithGoogle()

_.extend Template.sparkFilter,
  rendered: ->
    console.log 'spark filter rendered'
    ts.setEditable
      node: $('#filter-finished')
      value: -> ts.State.sparkFinishFilter.get()
      source: -> ts.consts.filter.FINISHED
      renderCallback: (e, editable) ->
        value = parseInt editable.value
        switch value
          when 0 then value = {id: 0, name: '全部'}
          when 1 then value = {id: 1, name: '未完成'}
          when 2 then value = {id: 2, name: '已完成'}

        ts.State.sparkFinishFilter.set value

    ts.setEditable
      node: $('#filter-priority')
      value: -> ts.State.sparkPriorityFilter.get()
      source: ->
        priorities = ts.consts.filter.PRIORITY
        priorities['all'] = '全部'
        return priorities
      renderCallback: (e, editable) ->
        if editable.value is 'all'
          value = {id: 'all', name: '全部'}
        else
          v = parseInt editable.value
          value = {id: v, name: v}

        ts.State.sparkPriorityFilter.set value

    ts.setEditable
      node: $('#filter-deadline')
      value: ->
        v = ts.State.sparkDeadlineFilter.get()
        switch v
          when ts.consts.EXPIRE_IN_3_DAYS then 1
          when ts.consts.EXPIRE_IN_1_WEEK then 2
          when ts.consts.EXPIRE_IN_2_WEEKS then 3
          else 0
      source: -> ts.consts.filter.DEADLINE
      renderCallback: (e, editable) ->
        value = parseInt editable.value
        switch value
          when 1 then deadline = ts.consts.EXPIRE_IN_3_DAYS
          when 2 then deadline = ts.consts.EXPIRE_IN_1_WEEK
          when 3 then deadline = ts.consts.EXPIRE_IN_2_WEEKS
          else deadline = 'all'
        ts.State.sparkDeadlineFilter.set {id: deadline, name: value}

    ts.setEditable
      node: $('#filter-spark-type')
      value: -> ts.State.sparkTypeFilter.get()
      source: ->
        types = ts.consts.filter.TYPE()
        types['all'] = '全部'
        return types

      renderCallback: (e, editable) ->
        if editable.value is 'all'
          value = {id: 'all', name: '全部'}
        else
          value = {id: editable.value, name: ts.consts.filter.TYPE()[editable.value]}
        ts.State.sparkTypeFilter.set value

    ts.setEditable
      node: $('#filter-author')
      value: -> ts.State.sparkAuthorFilter.get()
      source: ->
        members = ts.consts.filter.MEMBERS()
        members['all'] = '全部'
        return members
      renderCallback: (e, editable) ->
        if editable.value is 'all'
          user = {id: 'all', username: '全部'}
        else
          user = Meteor.users.findOne _id: editable.value
        ts.State.sparkAuthorFilter.set {id: user._id, name: user.username}

    ts.setEditable
      node: $('#filter-owner')
      value: -> ts.State.sparkOwnerFilter.get()
      source: -> ts.consts.filter.MEMBERS()
      renderCallback: (e, editable) ->
        if editable.value is 'all'
          user = {id: 'all', username: '全部'}
        else
          user = Meteor.users.findOne _id: editable.value
        ts.State.sparkOwnerFilter.set {id: user._id, name: user.username}

    ts.setEditable
      node: $('#filter-tag')
      value: -> ts.State.sparkTagFilter.get()
      source: -> ts.consts.filter.TAGS()
      renderCallback: (e, editable) ->
        if editable.value is 'all'
          tag = {id: 'all', name: '全部'}
        else
          tag = {id: editable.value, name: editable.value}
        ts.State.sparkTagFilter.set tag

    $('#search-spark').select2(
      placeholder: '搜索当前项目下的任务'
      minimumInputLength: 1
      formatResult: ts.select2.formatSpark
      #formatSelection: ts.select2.formatSpark
      formatInputTooShort: (input, min) ->
        creators = []
        _.each Template.sparkFilter.types(), (item) ->
          creators.push("<a data-id='#{item.id}' data-name='#{item.name}' href='javascript:;' onclick=ts.createSparkFunc('#{item.id}');><i class='#{item.icon}' ></i>#{item.name}</a> ")

        "<span class='pull-right' id='spark-creators'>新建：#{creators.join(' | ')}</span>"

      query: (query) ->
        projectId = ts.State.filterSelected.get()
        regex = new RegExp query.term, 'i'
        sparks = Sparks.find(projects: projectId, $or: [{title: regex}, {issueId: regex}, {tags: regex}]).fetch()


        data = results: _.map(sparks, (spark) ->
          ret =
            id: spark._id
            issueId: spark.issueId
            text:spark.title
            createdAt: spark.createdAt
            authorId: spark.authorId
            tags: spark.tags
            content: ts.stripTags(spark.content).slice(0, 80)
        )
        #data = {results: sparks}

        query.callback(data)

    ).off('change').on('change', (e) ->  Router.setSpark e.val)

  events:
    'click .shortcut': (e) ->
      type = $(e.currentTarget).data('id')

      switch type
        when 'upcoming'
          ts.State.clearFilters()
          ts.State.sparkDeadlineFilter.set {id: ts.consts.EXPIRE_IN_3_DAYS, name: 1}
        when 'created'
          ts.State.clearFilters()
          user = Meteor.user()
          ts.State.sparkAuthorFilter.set {id: user._id, name: user.username}
        when 'finished'
          ts.State.clearFilters()
          ts.State.sparkFinishFilter.set {id: 2, name: '已完成'}


    'click #clear-filter': (e) ->
      ts.State.clearFilters()

    'click #spark-sort > li > a': (e) ->
      $node = $(e.currentTarget)
      value = {id: $node.data('id'), name: $node.data('name')}
      ts.State.sparkOrder.set value

  types: -> ts.sparks.types()


  finishText: -> ts.State.sparkFinishFilter.getName()

  typeText: -> ts.State.sparkTypeFilter.getName()

  priorityText: -> ts.State.sparkPriorityFilter.getName()

  deadlineText: -> ts.consts.filter.DEADLINE[ts.State.sparkDeadlineFilter.getName()]

  authorText: ->
    ts.State.sparkAuthorFilter.getName()

  ownerText: ->
    ts.State.sparkOwnerFilter.getName()

  tagText: ->
    ts.State.sparkTagFilter.getName()
  orderText: ->
    ts.State.sparkOrder.getName()

_.extend Template.sparkContentEditor,
  rendered: ->
    console.log 'spark content rendered'
    ts.editor().panelInstance 'spark-content', hasPanel : true

_.extend Template.sparkEdit,
  events:
    'click #edit-spark-cancel': (e) ->
      $('#edit-spark form')[0].reset()
      $('#edit-spark').modal 'hide'

    'click #edit-spark-submit': (e) ->
      $node = $('#edit-spark')
      id = $node.data('id')
      title = $('#spark-edit-title').val()
      content = nicEditors.findEditor('spark-edit-content').nicInstances?[0].getContent()
      spark = Sparks.findOne _id: id
      if spark.title != title
        Actions.updateSpark id, title, 'title'

      if spark.content != content
        Actions.updateSpark id, content, 'content'

      $('form', $node)?[0].reset()
      $node.modal 'hide'

_.extend Template.sparkInput,
  rendered: ->
    console.log 'spark input rendered'
    usernames = _.pluck ts.members.all().fetch(), 'username'
    $node = $('#spark-owner')

    $node.select2
      tags: usernames
      placeholder:'添加责任人'
      tokenSeparators: [' ']
      separator:';'

    $node = $('#spark-tags')
    $node.select2
      tags: _.pluck ts.tags.all().fetch(), 'name'
      placeholder: '添加标签'
      tokenSeparators: [' ']
      separator:';'

    $node = $('#spark-deadline')
    if not $node.data('done')
      $node.data('done', 'done')
      $node.datepicker({format: 'yyyy-mm-dd'}).on 'changeDate', (ev) -> $node.datepicker('hide')

  events:
    'click #add-spark-cancel': (e) ->
      $('#add-spark form')[0].reset()
      $('#add-spark').modal 'hide'

    'click #add-spark-submit': (e) ->
      $form = $('#add-spark form')
      $title = $('input[name="title"]', $form)
      title = $.trim($title.val())

      if not title
        $title.parent().addClass 'error'
        return null

      content = nicEditors.findEditor('spark-content').nicInstances?[0].getContent()
      priority = parseInt $('select[name="priority"]').val()
      type = ts.State.sparkToCreate.get()
      if ts.filteringProject()
        project = ts.State.filterSelected.get()
      else
        project = $('select[name="project"]', $form).val()

      # use $in will make the order wrong
      #owners = Meteor.users.find teamId: ts.State.teamId.get(), username: $in: $('input[name="owner"]', $form).val().split(';')
      #owners = _.map owners.fetch(), (item) -> item._id

      owners = $.trim($('input[name="owner"]', $form).val())
      if owners
        owners = _.map owners.split(';'), (username) ->
          user = Meteor.users.findOne {teamId: ts.State.teamId.get(), username: username}, {fields: '_id'}
          return user?._id
        owners = _.filter owners, (id) -> id
      else
        owners = []

      tags = $.trim($('input[name="tags"]', $form).val()).split(';')
      deadlineStr = $('input[name="deadline"]', $form).val()


      #console.log "name: #{name}, desc: #{content}, priority: #{priority}, type: #{type}, project: #{project}, owners:", owners, deadlineStr

      Actions.createSpark title, content, type, project, owners, priority, tags, deadlineStr
      $('.control-group', $form).removeClass 'error'
      $form[0].reset()
      $('#add-spark').modal 'hide'

_.extend Template.notifications,
  events:
    'click .notification > a': (e) ->
      e.preventDefault()
      Actions.notificationRead @_id
      Router.setSpark @sparkId

  totalUnread: ->
    Notifications.find(readAt:null).count()

  hasUnread: ->
    if Template.notifications.totalUnread() > 0
      return 'has-unread'
    return ''

  topNotifications: ->
    Notifications.find {readAt:null}, {sort: createdAt: -1}

  showNotification: ->
    if not @visitedAt
      Actions.notificationVisited @_id
      $.pnotify
        title: "#{@title}",
        text: @content,
        type: ts.consts.notifications[@level]

_.extend Template.createTeam,
  events:
    'click #btn-create-team': (e) ->
      e.preventDefault()
      name = $.trim $('#teamname').val()
      if name
        Actions.createTeam name

Meteor.startup ->
  $(window).focus ->
    profile = Profiles.findOne userId: Meteor.userId()
    #console.log 'online:', profile.username
    if profile and not profile.online
      Actions.online true

  $(window).blur ->
    profile = Profiles.findOne userId: Meteor.userId()
    #console.log 'offline:', profile.username
    if profile and profile.online
      Actions.online false
