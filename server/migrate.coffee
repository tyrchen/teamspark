Meteor.methods
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

  migrateFinishedAt: ->
    sparks = Sparks.find(finished:true).fetch()
    _.each sparks, (item) ->
      Sparks.update item._id, $set: finishedAt: item.updatedAt

