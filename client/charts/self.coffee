ts = ts || {}
ts.charts = ts.charts || {}

ts.charts.self = ts.charts.self || {}

ts.charts.self.data =  ->
  stats = ts.charts.stats()
  user = Meteor.user()
  positioned = []
  finished = []
  _.each stats, (stat) ->
    if stat['positioned'][user._id]
      positioned.push x: stat.date, y: stat['positioned'][user._id][0]
    else
      positioned.push x: stat.date, y: 0

    if stat['finished'][user._id]
      finished.push x: stat.date, y: stat['finished'][user._id][0]
    else
      finished.push x: stat.date, y: 0

  return [
    {values: positioned, key: '发表', color: '#ff7f0e'},
    {values: finished, key: '完成', color: '#2ca02c'}
  ]

ts.charts.self.graph = ->
  chartNode = "#chart-self svg"
  chart = nv.models.multiBarChart()
  chart.xAxis.tickFormat (d) ->
    d3.time.format('%x')(new Date(d))

  data = ts.charts.self.data()
  #console.log 'self:', data, $(chartNode)
  chart.yAxis.tickFormat(d3.format(',f'))
  d3.select(chartNode)
    .datum(data)
    .transition().duration(500)
    .call(chart)

  nv.utils.windowResize -> d3.select(chartNode).call(chart)
