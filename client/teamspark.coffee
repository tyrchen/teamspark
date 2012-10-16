ts = ts || {}
ts.filteringTeam = ->
  ts.State.filterType.get() is 'team'

ts.filteringUser = ->
  ts.State.filterType.get() is 'user'

ts.filteringProject = ->
  ts.State.filterSelected.get() isnt 'all'

_.extend Template.content,
  loggedIn: -> Meteor.userId
  teamActivity: -> ts.State.activityDisplay.get() is 'team'
  projects: -> Projects.find()
  teamName: -> ts.currentTeam()?.name

_.extend Template.projects,
  events:
    'click #filter-team': (e) ->
      ts.State.filterType.set 'team'

    'click #filter-member': (e) ->
      ts.State.filterType.set 'user'


    'click .filter-project': (e) ->
      $node = $(e.currentTarget)
      id = $node.data('id')
      name = $node.data('name')

      if id == ''
        ts.State.filterSelected.set {id: 'all', name: 'all'}
      else
        ts.State.filterSelected.set {id: id, name: name}

    'click #add-project': (e) ->
      $('#add-project-dialog').modal()

    'click #add-project-submit': (e) ->
      $form = $('#add-project-dialog form')
      $name = $('input[name="name"]', $form)
      name = $name.val()
      description = $('textarea[name="description"]', $form).val()
      parentId = $('select[name="parent"]', $form).val()
      if parentId is 'null'
        parentId = null
      console.log "name: #{name}, desc: #{description}, parent: #{parentId}"
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
      console.log this._id, ts.currentTeam().authorId
      if this._id is ts.currentTeam().authorId
        return

      $this = $(e.currentTarget)
      console.log 'this: ', $this
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

  totalUnfinished: (id=null) ->
    ts.sparks.totalUnfinished id

  hasProject: -> Projects.find().count()

  projects: -> Projects.find()

  parentProjects: -> Projects.find parent: null

  childProjects: (id)-> Projects.find parent: id

_.extend Template.sparks,
  sparks: ->
    project = ts.State.filterSelected.get()
    order = ts.State.sparkOrder.get()
    type = ts.State.sparkTypeFilter.get()
    priority = ts.State.sparkPriorityFilter.get()
    author = ts.State.sparkAuthorFilter.get()
    owner = ts.State.sparkOwnerFilter.get()
    progress = ts.State.sparkProgressFilter.get()

    query = []
    # spark = {
    # _id: uuid, type: 'idea', authorId: userId, auditTrails: [],
    # currentOwnerId: userId, nextStep: 1, owners: [userId, ...], progress: 10
    # title: 'blabla', content: 'blabla', priority: 1, supporters: [userId1, userId2, ...],
    # finished: false, projects: [projectId, ...], deadline: Date(), createdAt: Date(),
    # updatedAt: Date(), teamId: teamId
    # }
    if project isnt 'all'
      query.push projects: project

    if type isnt 'all'
      query.push type: type

    if priority isnt 'all'
      query.push priority: priority

    if author isnt 'all'
      query.push authorId: author

    if owner isnt 'all'
      query.push currentOwnerId: owner

    if progress isnt 'all'
      query.push progress: progress

    if order is 'createdAt'
      Sparks.find {$and: query}, {sort: createdAt: -1}
    else
      Sparks.find {$and: query}, {sort: updatedAt: -1}

_.extend Template.sparkFilter,
  events:
    'click .spark-list > li': (e) ->
      $node = $(e.currentTarget)
      id = $node.data('id')
      name = $node.data('name')

      ts.State.sparkToCreate.set {id: id, name: name}

      usernames = _.pluck ts.members().fetch(), 'username'
      $node = $('#spark-owner')
      $node.select2
        tags: usernames

        placeholder:'添加责任人'
        tokenSeparators: [' ']
        separator:';'

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

_.extend Template.sparkInput,
  events:
    'click #add-spark-cancel': (e) ->
      $('#add-spark form')[0].reset()
      $('#add-spark').modal 'hide'

    'click #add-spark-submit': (e) ->
      $form = $('#add-spark form')
      $title = $('input[name="title"]', $form)
      title = $.trim($title.val())
      content = $('textarea[name="content"]', $form).val()
      priority = parseInt $('select[name="priority"]').val()
      type = ts.State.sparkToCreate.get()
      if ts.filteringProject()
        project = ts.State.filterSelected.get()
      else
        project = $('select[name="project"]', $form).val()

      owners = $('input[name="owner"]', $form).val().split(';')
      owners = _.map owners, (item) -> Meteor.users.findOne({username: item})?._id


      console.log "name: #{name}, desc: #{content}, priority: #{priority}, type: #{type}, project: #{project}, owners:", owners

      if not title
        $title.parent().addClass 'error'
        return null

      Meteor.call 'createSpark', title, content, type, project, owners, priority, (error, result) ->
        $('.control-group', $form).removeClass 'error'
        $form[0].reset()
        $('#add-spark').modal 'hide'

  projects: -> Projects.find()