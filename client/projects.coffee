# project = { _id: uuid, name: 'cayman', description: 'cayman is a project', authorId: null, parentId: null, teamId: teamId, createdAt: Date() }

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
    ts.sparks.totalUnfinished id, null

  hasProject: -> Projects.find().count()

  projects: -> Projects.find()

  parentProjects: -> Projects.find parent: null

  childProjects: (id)-> Projects.find parent: id