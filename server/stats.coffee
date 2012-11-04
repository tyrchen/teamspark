ts = ts || {}
ts.stats = ts.stats || {}
ts.stats.createDayStat = (date, teamId, projectId) ->
  l = [0, 0, 0, 0, 0, 0]
  data = {total: l}
  _.each Meteor.users.find(teamId:teamId).fetch(), (user) ->
    data[user._id] = l

  DayStats.insert
    date: date
    teamId: teamId
    projectId: projectId
    positioned: data
    finished: data

ts.stats.getIncCmd = (spark, type, users = [], value=1) ->
  pos = ts.sparks.typesPos[spark.type]
  userId = Meteor.userId()

  incCmd = {}
  incCmd["#{type}.total.0"] = value
  incCmd["#{type}.total.#{pos}"] = value
  _.each users, (userId) ->
    incCmd["#{type}.#{userId}.0"] = value
    incCmd["#{type}.#{userId}.#{pos}"] = value

  return incCmd



ts.stats.trackDaySpark = (spark, date, type="positioned", value=1) ->
  #date = ts.toDate(ts.now())
  _.each spark.projects, (id) ->
    dayStatId = DayStats.findOne(date: date, teamId: spark.teamId, projectId: id)?._id
    if not dayStatId
      dayStatId = ts.stats.createDayStat date, Meteor.user().teamId, id

    if type is 'positioned'
      users = [spark.authorId]
    else
      users = spark.finishers || []

    incCmd = ts.stats.getIncCmd spark, type, users, value
    DayStats.update dayStatId, $inc: incCmd
    console.log 'track spark:', spark.title, ts.formatDate(date), type, value, incCmd, id, users


Meteor.methods
  trackPositioned: (sparkId, value=1) ->
    if sparkId._id
      spark = sparkId
    else
      spark = Sparks.findOne _id: sparkId

    if not spark?.positionedAt
      throw new Meteor.Error 400, "spark #{spark.title} has not yet been positioned"

    positionedDate = ts.toDate spark.positionedAt

    ts.stats.trackDaySpark spark, positionedDate, 'positioned', value



  trackFinished: (sparkId) ->
    if sparkId._id
      spark = sparkId
    else
      spark = Sparks.findOne _id: sparkId

    if not spark?.finished
      throw new Meteor.Error 400, "spark #{spark.title} has not yet been finished"

    finishedDate = ts.toDate spark.finishedAt
    ts.stats.trackDaySpark spark, finishedDate, 'finished', 1





