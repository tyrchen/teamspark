ts = ts || {}
ts.charts = ts.charts || {}

ts.charts.stats = ->
  projectId = ts.State.filterSelected.get()
  if projectId is 'all'
    q = {}
  else
    q = {projectId: projectId}
  return DayStats.find(q, {sort: date: 1}).fetch()




_.extend Template.charts,
  rendered: ->
    width = Math.floor(($('.spark-panel').width() - 35) / 4 - 5)
    height = Math.floor(width * 0.8)

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
    ts.charts.distribution.graph('positioned')
    ts.charts.distribution.graph('finished')


  widgets: ->
    amplify.store('chart_layout') || ts.consts.charts.layout

  chart: ->
    switch @name
      when 'catchup' then ts.charts.catchup.graph()
      when 'distribution-positioned' then ts.charts.distribution.graph('positioned')
      when 'distribution-finished' then ts.charts.distribution.graph('finished')
