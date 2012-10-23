ts = ts || {}
ts.setEditable = (options) ->
  defaults =
    type: 'select'
    placement: 'right'
    name: 'dummy'
    pk: null
    callback: null
    value: -> null
    source: -> null
    renderCallback: (e, editable) ->
    showCallback: (e, editable) ->

  defaults = _.extend defaults, options

  defaults.node.editable(
    type: defaults.type
    value: defaults.value
    placement: defaults.placement
    name: defaults.name
    pk: defaults.pk
    source: defaults.source
  ).on('render', (e, editable) ->
    defaults.renderCallback(e, editable)
  )

ts.isIphone = ->
  navigator.userAgent.match(/iPhone|iPod/i)?

ts.isIpad = ->
  navigator.userAgent.match(/iPad/i)?