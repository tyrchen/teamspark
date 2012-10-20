ts = ts || {}
ts.filteringTeam = ->
  ts.State.filterType.get() is 'team'

ts.filteringUser = ->
  ts.State.filterType.get() is 'user'

ts.filteringProject = ->
  ts.State.filterSelected.get() isnt 'all'

_.extend Template.content,
  events:
    'click #manage-member': (e) ->
      $('#manage-member-dialog').modal()
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
      Meteor.call 'updateMembers', added_ids, removed_ids, (error, result) ->
        $('#manage-member-dialog').modal 'hide'


    'click #logout': (e) ->
      Meteor.logout()

  loggedIn: -> Meteor.userId
  projects: -> Projects.find()
  teamName: -> ts.currentTeam()?.name
  isOrphan: ->
    if not Meteor.user().teamId
      return 'orphan'
    return ''


_.extend Template.sparkFilter,
  events:
    'click .spark-list > li': (e) ->
      $node = $(e.currentTarget)
      id = $node.data('id')
      name = $node.data('name')

      ts.State.sparkToCreate.set {id: id, name: name}
      $('#add-spark').modal()

    'click #filter-spark-author > li': (e) ->
      $node = $(e.currentTarget)
      id = $node.data('id')
      name = $node.data('name')

      if id == ''
        ts.State.sparkAuthorFilter.set {id: 'all', name: 'all'}
      else
        ts.State.sparkAuthorFilter.set {id: id, name: name}

    'click #filter-spark-owner > li': (e) ->
      $node = $(e.currentTarget)
      id = $node.data('id')
      name = $node.data('name')

      if id == ''
        ts.State.sparkOwnerFilter.set {id: 'all', name: 'all'}
      else
        ts.State.sparkOwnerFilter.set {id: id, name: name}

    'click #filter-spark-type > li': (e) ->
      $node = $(e.currentTarget)
      id = $node.data('id')
      name = $node.data('name')

      if id == ''
        ts.State.sparkTypeFilter.set {id: 'all', name: 'all'}
      else
        ts.State.sparkTypeFilter.set {id: id, name: name}

    'click #hide-finished': (e) ->
      finish = ts.State.sparkFinishFilter.get()
      ts.State.sparkFinishFilter.set(not finish)

  types: -> ts.sparks.types()


  isAuthorSelected: (id='all') ->
    if ts.State.sparkAuthorFilter.get() is id
      return 'icon-ok'
    return ''

  isOwnerSelected: (id='all') ->
    if ts.State.sparkOwnerFilter.get() is id
      return 'icon-ok'
    return ''

  isTypeSelected: (id='all') ->
    if ts.State.sparkTypeFilter.get() is id
      return 'icon-ok'
    return ''

  hideFinished: ->
    if ts.State.sparkFinishFilter.get()
      return 'checked'
    return ''

_.extend Template.sparkContentEditor,
  rendered: ->
    ts.editor().panelInstance 'spark-content', hasPanel : true

_.extend Template.sparkEdit,
  rendered:
    console.log 'spark edit rendered', @

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
        console.log 'title changed:', id, title
        Meteor.call 'updateSpark', id, title, 'title'

      if spark.content != content
        console.log 'content changed:', id, content
        Meteor.call 'updateSpark', id, content, 'content'

      $('form', $node)?[0].reset()
      $node.modal 'hide'

_.extend Template.sparkInput,
  rendered: ->
    console.log 'spark input rendered', @
    usernames = _.pluck ts.members().fetch(), 'username'
    $node = $('#spark-owner')

    $node.select2
      tags: usernames
      placeholder:'添加责任人'
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

      deadlineStr = $('input[name="deadline"]', $form).val()


      console.log "name: #{name}, desc: #{content}, priority: #{priority}, type: #{type}, project: #{project}, owners:", owners, deadlineStr

      Meteor.call 'createSpark', title, content, type, project, owners, priority, deadlineStr, (error, result) ->
        $('.control-group', $form).removeClass 'error'
        $form[0].reset()
        $('#add-spark').modal 'hide'