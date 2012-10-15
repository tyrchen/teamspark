ts = ts || {}
ts.filteringTeam = ->
  ts.State.filterType == 'team'

ts.filteringUser = ->
  ts.State.filterType == 'user'

_.extend Template.content,
  loggedIn: -> Meteor.userId
  teamActivity: -> ts.State.activityDisplay.get()
  members: -> Meteor.users.find()
  projects: -> Projects.find()

_.extend Template.shortcuts,
  events:
    'click': -> alert('aa')

_.extend Template.projects,
  events:
    'click #add-project': (e) ->
      $('#add-project-dialog').modal()

    'click #add-project-submit': (e) ->
      $form = $('#add-project-dialog form')
      name = $('input[name="name"]', $form).val()
      description = $('textarea[name="description"]', $form).val()
      parentId = $('select[name="parent"]', $form).val()
      console.log "name: #{name}, desc: #{description}, parent: #{parentId}"
      Meteor.call 'createProject', name, description, null, (error, result) ->
        $('#add-project-dialog').modal 'hide'

    'click #add-project-cancel': (e) ->
      $('#add-project-dialog').modal 'hide'

  hasProject: -> Projects.find().count()

  projects: -> Projects.find()
