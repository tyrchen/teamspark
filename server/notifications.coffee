Meteor.methods
  notify: (recipients, title, content, sparkId, type=1, level=2) ->
    # notification = {
    # _id: uuid, recipientId: userId, level: 1-5|debug|info|warning|important|urgent
    # type: 1-5 | user | spark | project | team | site
    # title: 'bla', content: 'html bla', sparkId: sparkId, createdAt: new Date(), readAt: new Date(), visitedAt: new Date() }
    if not recipients or not title
      return

    actor = Meteor.userId()
    all = _.without recipients, actor

    if not all
      return

    #console.log 'Notify: from ', actor, 'to ', all, " with #{title}, #{content} and sparkId is #{sparkId}"

    _.each all, (id) ->
      Notifications.insert
        actorId: actor
        recipientId: id
        level: level
        type: type
        title: title
        content: content
        sparkId: sparkId
        createdAt: ts.now()

  notificationVisited: (nid) ->
    Notifications.update nid, $set: visitedAt: ts.now()

  notificationRead: (nid) ->
    Notifications.update nid, $set: readAt: ts.now()