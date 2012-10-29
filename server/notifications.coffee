Meteor.methods
  notify: (recipients, title, content, sparkId, type=1, level=2) ->
    # notification = {
    # _id: uuid, recipientId: userId, level: 1-5|debug|info|warning|important|urgent
    # type: 1-5 | user | spark | project | team | site
    # title: 'bla', content: 'html bla', sparkId: sparkId, createdAt: new Date(), readAt: new Date(), visitedAt: new Date() }
    recpipients = _.without recipients, Meteor.userId()

    console.log 'Notify:', recipients, " with #{title}, #{content} and sparkId is #{sparkId}"

    _.each recipients, (id) ->
      Notifications.insert
        actorId: Meteor.userId()
        recipientId: id
        level: level
        type: type
        title: title
        content: content
        sparkId: sparkId
        createdAt: ts.now()

  notificationVisited: (nid) ->
    Notifications.update nid, visitedAt: ts.now()

  notificationRead: (nid) ->
    Notifications.update nid, readAt: ts.now()