ts = ts || {}
ts.charts = ts.charts || {}

ts.charts.self = ts.charts.self || {}

ts.charts.self.data =  ->
  stats = ts.charts.stats()
  user = Meteor.user()
  positioned = []
  finished = []
  _.each stats, (stat) ->
    positioned.push x: stat.date, y: stat['positioned'][user._id][0]
    finished.push x: stat.date, y: stat['finished'][user._id][0]

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
