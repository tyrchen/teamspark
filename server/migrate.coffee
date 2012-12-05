Meteor.methods
  migrateProfiles: ->
    if Profiles.find().count() is 0
      users = Meteor.users.find().fetch()
      _.each users, (user) ->
        Profiles.insert
          userId: user._id
          username: user.username
          online: false
          teamId: user.teamId

  migrateUserPoints: ->
    if not Meteor.user().points
      users = Meteor.users.find().fetch()
      _.each users, (user) ->
        totalCreated = Sparks.find(authorId: user._id).count() * ts.consts.points.CREATE_SPARK
        totalFinished = Sparks.find({owners: user._id, finished: true}).count() * ts.consts.points.FINISH_SPARK
        Meteor.users.update user._id, $set: points: totalCreated + totalFinished

  migrateSparkFinishers: ->
    sparks = Sparks.find().fetch()
    _.each sparks, (spark) ->
      if spark.finishers
        return

      owners = spark.owners
      if spark.finished
        Sparks.update spark._id, $set: {owners: [], finishers: owners}
        return

      found = false
      finishers = []
      _.each owners, (userId) ->
        if not found
          if userId is spark.currentOwnerId
            found = true
          else
            finishers.push userId

      Sparks.update spark._id, $set: {finishers: finishers}, $pullAll: {owners: finishers}

  migrateProfileTime: ->
    profiles = Profiles.find().fetch()
    _.each profiles, (p) ->
      totalCreated = Sparks.find(authorId: p.userId).count()
      totalFinished = Sparks.find(finished: true, finishers: p.userId).count()
      seconds = totalCreated * 120 + totalFinished * 240
      Profiles.update {userId: p.userId}, {$set: totalSeconds: seconds}

  migratePoints: ->
    sparks = Sparks.find().fetch()
    _.each sparks, (item) ->
      totalPoints = item.finishers.length * ts.consts.points.FINISH_SPARK
      Sparks.update item._id, $set: {totalPoints: totalPoints, points: ts.consts.points.FINISH_SPARK}

  migrateTotalSupporters: ->
    sparks = Sparks.find().fetch()
    _.each sparks, (item) ->
      Sparks.update item._id, $set: totalSupporters: item.supporters.length

  migratePositionedAt: ->
    sparks = Sparks.find().fetch()
    _.each sparks, (item) ->
      if item.auditTrails?.length > 0
        history = _.find item.auditTrails, (h) -> h.content?.indexOf('更新了项目') > 0
      else
        history = null

      if history
        command = positionedAt: history.createdAt
      else
        command = positionedAt: item.createdAt
      Sparks.update item._id, $set: command

  migrateFinishedAt: ->
    sparks = Sparks.find(finished:true).fetch()
    _.each sparks, (item) ->
      Sparks.update item._id, $set: finishedAt: item.updatedAt

  migrateStat: ->
    sparks = Sparks.find({}).fetch()
    _.each sparks, (item) ->
      Meteor.call 'trackPositioned', item
      if item.finished
        Meteor.call 'trackFinished', item

  migrateTags: ->
    Tags.update {projectId: null}, {$set: projectId: '1b6c3590-c26a-49ea-96f7-d07f0e95fc74'}

  migrateProjectStat: ->
    projects = Projects.find().fetch()
    _.each projects, (item) ->
      if item.parent
        unfinished = Sparks.find(projects: item._id, finished: false).count()
        finished = Sparks.find(projects: item._id, finished: true).count()
        verified = Sparks.find(projects: item._id, finished: true, verified: $ne: null).count()
      else
        unfinished = Sparks.find(projects: [item._id], finished: false).count()
        finished = Sparks.find(projects: [item._id], finished: true).count()
        verified = Sparks.find(projects: [item._id], finished: true, verified: $ne: null).count()

      Projects.update item._id, $set: {unfinished: unfinished, finished: finished, verified: verified}

  migrateUserStat: ->
    #   totalSubmitted: 0, totalActive: 0, totalFinished: 0
    profiles = Profiles.find().fetch()
    _.each profiles, (item) ->
      submitted = Sparks.find(authorId: item.userId).count()
      unfinished = Sparks.find(finished: false, owners: item.userId).count()
      finished = Sparks.find(finishers: item.userId).count()

      Profiles.update item._id, $set: {totalSubmitted: submitted, totalUnfinished: unfinished, totalFinished: finished}

  migrateSparkVerified: ->
    Sparks.update {finished: false}, {$set: verified: false}, {multi: true}
    Sparks.update {finished: true}, {$set: verified: true}, {multi: true}
    console.log 'total unverified:', Sparks.find(verified:false).count(), ', total verified: ', Sparks.find(verified:true).count()

  migrateSparkIssueId: (abbr) ->
    user = Meteor.user()
    teamId = user.teamId
    Teams.update teamId, $set: {abbr: abbr, nextIssueId: 1}

    sparks = Sparks.find({teamId: teamId}, {sort: createdAt: 1}).fetch()
    _.each sparks, (item) ->
      team = Teams.findOne teamId, fields: nextIssueId: 1
      Teams.update teamId, $inc: nextIssueId: 1
      console.log 'nextIssueId', team.nextIssueId
      Sparks.update item._id, $set: issueId: "#{abbr}#{team.nextIssueId}"