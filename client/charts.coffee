ts = ts || {}
ts.charts = ts.charts || {}
ts.charts.catchup = ts.charts.catchup || {}

ts.charts.catchup.data = ->
  projectId = ts.State.filterSelected.get()
  positioned = []
  finished = []

  if projectId is 'all'
    q = {}
  else
    q = {projectId: projectId}
  stats = DayStats.find(q).fetch()
  sumPositioned = 0
  sumFinished = 0
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
  chart = nv.models.lineChart()
  chart.xAxis.axisLabel('日期').tickFormat (d) ->
    d3.time.format('%x')(new Date(d))

  data = ts.charts.catchup.data()
  chart.yAxis.axisLabel('数量').tickFormat(d3.format(',r'))
  d3.select('#chart-catchup svg')
    .datum(data)
    .transition().duration(500)
    .call(chart)

  #nv.utils.windowResize -> d3.select('#chart-catchup svg').call(chart)
  console.log 'chart:', $('#chart-catchup svg'), data


_.extend Template.charts,
  rendered: ->
    width = Math.floor(($('.spark-panel').width() - 35) / 4 - 5)
    height = Math.floor(width * 0.618)

    $(".gridster > ul").gridster
      widget_margins: [5, 5]
      widget_base_dimensions: [width, height]
      serialize_params: ($w, wgd) ->
        {col: wgd.col, row: wgd.row, size_x: wgd.size_x, size_y: wgd.size_y, name: $w.data('name')}

      draggable:
        stop: (event, ui) ->
          g = $(".gridster > ul").gridster().data('gridster')
          amplify.store('chart_layout', g.serialize())
    ts.charts.catchup.graph()

  widgets: ->
    amplify.store('chart_layout') || ts.consts.charts.layout

  chart: ->
    switch @name
      when 'catchup' then ts.charts.catchup.graph()
