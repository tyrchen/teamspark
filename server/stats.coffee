ts = ts || {}
ts._createDayStat = (date, teamId) ->
  l = [0, 0, 0, 0, 0, 0]
  data = {total: l}
  _.each Meteor.users.find(teamId:teamId).fetch(), (user) ->
    data[user._id] = l

  DayStats.insert
    date: date
    teamId: teamId
    positioned: data
    finished: data
    
ts._trackDaySpark = (spark, type="positioned") ->
  date = ts.toDate(ts.now())
  dayStatId = DayStats.findOne(date: date)?._id
  if not dayStatId
    # dayStat = {
    #   _id: uuid, date: new Date(), teamId: teamId,
    #   positioned: { total: 1], userId2: [0, 0,0,0,0,0], ... } # index 0 is total[15, 1,2,3,4,5], userId1: [3, 1, 0, 0, 1,
    #   finished: { the same as created}
    # }
    dayStatId = ts._createDayStat date, Meteor.user().teamId

  pos = ts.sparks.typesPos[spark.type]
  userId = Meteor.userId()

  incCmd = {}
  incCmd["#{type}.total.0"] = 1
  incCmd["#{type}.total.#{pos}"] = 1
  incCmd["#{type}.#{userId}.0"] = 1
  incCmd["#{type}.#{userId}.#{pos}"] = 1

  DayStats.update dayStatId, $inc: incCmd

Meteor.methods
  trackCreated: (sparkId) ->
    spark = Sparks.findOne _id: sparkId
    ts._trackDaySpark spark, 'positioned'


