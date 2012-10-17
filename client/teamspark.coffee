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


_.extend Template.member,
  events:
    'click .member': (e) ->
      $node = $(e.currentTarget)
      $('.audit-trail-container', $node).toggle()
      $node.toggleClass('active')

  auditTrails: -> ts.audits.all @_id, null

  totalUnfinished: (projectId=null) ->
    ts.sparks.totalUnfinished projectId, @_id

  totalImportant: (projectId=null) ->
    ts.sparks.totalImportant projectId, @_id

  totalUrgent: (projectId=null) ->
    ts.sparks.totalUrgent projectId, @_id

_.extend Template.audit,
  created: ->
    moment(@createdAt).fromNow()

  info: ->
    user = Meteor.users.findOne _id: @userId
    @content.replace(user.username, '')