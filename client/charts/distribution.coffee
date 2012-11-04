ts = ts || {}
ts.charts = ts.charts || {}

ts.charts.distribution = ts.charts.distribution || {}

ts.charts.distribution.data = (statType = 'positioned') ->
  stats = ts.charts.stats()

  _.map ts.sparks.types(), (typeObj) ->
    data = []
    _.each stats, (stat) ->
      data.push x: stat.date, y: stat[statType].total[ts.sparks.typesPos[typeObj.id]]

    return {key: typeObj.name, values: data}

ts.charts.distribution.graph = (statType = 'positioned') ->
  chartNode = "#chart-distribution-#{statType} svg"
  chart = nv.models.multiBarChart()
  chart.xAxis.tickFormat (d) ->
    d3.time.format('%x')(new Date(d))

  data = ts.charts.distribution.data(statType)
  #console.log 'distribution:', data, $(chartNode)
  chart.yAxis.tickFormat(d3.format(',f'))
  d3.select(chartNode)
    .datum(data)
    .transition().duration(500)
    .call(chart)

  nv.utils.windowResize -> d3.select(chartNode).call(chart)
