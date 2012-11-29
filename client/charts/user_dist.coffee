ts = ts || {}
ts.charts = ts.charts || {}

ts.charts.userDistribution = ts.charts.userDistribution || {}

ts.charts.userDistribution.data =  (statType = 'finished') ->
  members = Meteor.users.find(teamId: Meteor.user().teamId).fetch()
  stats = ts.charts.stats()
  _.map members, (user) ->
    data = []
    _.each stats, (stat) ->
      if stat[statType][user._id]?[0]
        data.push x: stat.date, y: stat[statType][user._id][0]
      else
        data.push x: stat.date, y: 0

    return {key: user.username, values: data}

ts.charts.userDistribution.graph = (statType = 'finished') ->
  chartNode = "#chart-user-distribution-#{statType} svg"
  chart = nv.models.stackedAreaChart()
  chart.xAxis.tickFormat (d) ->
    d3.time.format('%x')(new Date(d))

  data = ts.charts.userDistribution.data(statType)
  #console.log 'userDistribution:', data, $(chartNode)
  chart.yAxis.tickFormat(d3.format(',f'))
  d3.select(chartNode)
    .datum(data)
    .transition().duration(500)
    .call(chart)

  nv.utils.windowResize -> d3.select(chartNode).call(chart)
