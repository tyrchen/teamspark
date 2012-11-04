ts = ts || {}
ts.charts = ts.charts || {}
ts.charts.catchup = ts.charts.catchup || {}

ts.charts.catchup.data = ->
  positioned = []
  finished = []
  sumPositioned = 0
  sumFinished = 0

  stats = ts.charts.stats()

  _.each stats, (stat) ->
    positioned.push x: stat.date, y: stat.positioned.total[0] + sumPositioned
    sumPositioned += stat.positioned.total[0]
    finished.push x: stat.date, y: stat.finished.total[0] + sumFinished
    sumFinished += stat.finished.total[0]

  return [
    {values: positioned, key: '发表', color: '#ff7f0e'},
    {values: finished, key: '完成', color: '#2ca02c'}
  ]



ts.charts.catchup.graph = ->
  chartNode = '#chart-catchup svg'
  chart = nv.models.lineChart()
  chart.xAxis.tickFormat (d) ->
    d3.time.format('%x')(new Date(d))

  data = ts.charts.catchup.data()
  chart.yAxis.tickFormat(d3.format(',f'))
  d3.select(chartNode)
    .datum(data)
    .transition().duration(500)
    .call(chart)

  nv.utils.windowResize -> d3.select(chartNode).call(chart)
