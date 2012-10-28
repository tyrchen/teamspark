_.extend Template.activities,
  events:
    'click #team-activity': (e) ->
      ts.State.activityDisplay.set 'team'

    'click #project-activity': (e) ->
      ts.State.activityDisplay.set 'project'

  isTeamActivity: ->
    if ts.State.activityDisplay.get() is 'team'
      return 'active'
    return ''

  isProjectActivity: ->
    if ts.State.activityDisplay.get() is 'project'
      return 'active'
    return ''

  orderedMembers: ->
    all = ts.members.all().fetch()

  orderedProjects: ->
    all = ts.projects.all().fetch()

_.extend Template.member,
  events:
    'click .member': (e) ->
      $node = $(e.currentTarget)
      $('.audit-trail-container', $node).toggle()
      $node.toggleClass('active')

  auditTrails: -> ts.audits.all @_id, null

  totalUnfinished: (projectId=null) ->
    ts.sparks.totalUnfinished projectId, @_id

  totalFinished: (projectId=null) ->
    ts.sparks.totalFinished projectId, @_id

  totalSubmitted: (projectId=null) ->
    ts.sparks.totalSubmitted @_id, projectId

  totalImportant: (projectId=null) ->
    ts.sparks.totalImportant projectId, @_id

  totalUrgent: (projectId=null) ->
    ts.sparks.totalUrgent projectId, @_id

  onlineClass: ->
    profile = Profiles.findOne userId: @_id
    if profile?.online
      return 'online'
    return 'offline'

  onlineTime: ->
    profile = Profiles.findOne userId: @_id
    if profile?.totalSeconds
      return ts.formatTime profile.totalSeconds
    return '0秒'

_.extend Template.project,
  events:
    'click .project': (e) ->
      $node = $(e.currentTarget)
      $('.audit-trail-container', $node).toggle()
      $node.toggleClass('active')

  auditTrails: -> ts.audits.all null, @_id

  totalUnfinished: (userId=null) ->
    ts.sparks.totalUnfinished @_id, userId

  totalImportant: (userId=null) ->
    ts.sparks.totalImportant @_id, userId

  totalUrgent: (userId=null) ->
    ts.sparks.totalUrgent @_id, userId

_.extend Template.audit,
  showInfo: ->
    ts.State.activityDisplay.get() is 'team'

  created: ->
    moment(@createdAt).fromNow()

  info: ->
    user = Meteor.users.findOne _id: @userId
    @content.replace(user.username, '')