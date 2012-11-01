_.extend Template.charts,
  rendered: ->
    $(".gridster > ul").gridster
      widget_margins: [5, 5]
      widget_base_dimensions: [170, 130]
      serialize_params: ($w, wgd) ->
        {col: wgd.col, row: wgd.row, size_x: wgd.size_x, size_y: wgd.size_y, name: $w.data('name')}

      draggable:
        stop: (event, ui) ->
          console.log 'hello world'
          g = $(".gridster > ul").gridster().data('gridster')
          amplify.store('chart_layout', g.serialize())

  widgets: ->
    amplify.store('chart_layout') || ts.consts.charts.layout
