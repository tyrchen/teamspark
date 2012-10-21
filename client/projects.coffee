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

  totalSparks: (id=null) ->
    query = ts.sparks.query(false)
    if id
      query.push projects: id

    Sparks.find($and: query).count()


  childProjects: (id)-> ts.projects.children id
