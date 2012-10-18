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


