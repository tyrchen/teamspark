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

ts.stats.createWeekStat = (date, teamId, projectId) ->
  l = [0, 0, 0, 0, 0, 0]
  data = {total: l}
  _.each Meteor.users.find(teamId:teamId).fetch(), (user) ->
    data[user._id] = l

  WeekStats.insert
    date: date
    teamId: teamId
    positioned: data
    finished: data
    burned: [0, 0, 0, 0, 0, 0, 0]

ts.stats.getIncCmd = (spark, type, value) ->
  pos = ts.sparks.typesPos[spark.type]
  userId = Meteor.userId()

  incCmd = {}
  incCmd["#{type}.total.0"] = value
  incCmd["#{type}.total.#{pos}"] = value
  incCmd["#{type}.#{userId}.0"] = value
  incCmd["#{type}.#{userId}.#{pos}"] = value

  return incCmd



ts.stats.trackDaySpark = (spark, type="positioned", value=1) ->
  date = ts.toDate(ts.now())
  dayStatId = DayStats.findOne(date: date)?._id
  if not dayStatId
    dayStatId = ts.stats.createDayStat date, Meteor.user().teamId

  incCmd = ts.stats.getIncCmd spark, type, value
  DayStats.update dayStatId, $inc: incCmd

ts.stats.trackWeekSpark = (spark, type="positioned", value=1) ->
  date = ts.toMonday(ts.now())
  weekday = ts.toWeekday(ts.now())
  weekStatId = WeekStats.findOne(date:date)?._id
  if not weekStatId
    weekStatId = ts.stats.createWeekStat date, Meteor.user().teamId

  incCmd = ts.stats.getIncCmd spark, type, value

  switch type
    when 'positioned'
      while weekday <= 7
        incCmd["burned.#{weekday}"] = value
        weekday += 1

    when 'finished'


Meteor.methods
  trackCreated: (sparkId) ->
    spark = Sparks.findOne _id: sparkId
    ts._trackDaySpark spark, 'positioned'


