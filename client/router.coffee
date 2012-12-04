ts = ts || {}
ts.setProject = (project_name) ->
  project_name = decodeURIComponent(project_name)

  project = {_id: 'all', name: '全部'}
  if project_name is '全部'
    return

  # here we need to delay initial url parsing since data hasn't arrived
  Meteor.autorun (handle)->
    project = null
    if not Meteor.user().teamId
      return
    project = Projects.findOne name:project_name, teamId: Meteor.user().teamId
    if not project
      return

    handle.stop()

    if project
      ts.State.filterSelected.set
        id: project._id
        name: project.name

TsRouter = Backbone.Router.extend
  routes:
    '': 'home'
    'projects/:project_name/sparks': 'sparks'
    'projects/:project_name/charts': 'charts'
    'projects/:project_name/schedule': 'schedule'

    'sparks/:spark_id': 'spark'

  home: ->
    self = @
    lastProject =  amplify.store('project')
    if lastProject
      self.navigate "/projects/#{lastProject}/sparks", true
      return

    Meteor.autorun (handle) ->
      p = Projects.findOne {}, {sort: createdAt: 1}
      if p
        handle.stop()
        self.navigate "/projects/#{p.name}/sparks", true

  sparks: (project_name) ->
    ts.State.showContent.set 'sparks'
    ts.setProject project_name

  charts: (project_name) ->
    ts.State.showContent.set 'charts'
    ts.setProject project_name

  schedule: (project_name) ->
    ts.State.showContent.set 'schedule'
    ts.setProject project_name


  spark: (spark_id) ->
    Meteor.autorun (handle) ->
      spark = Sparks.findOne _id: spark_id
      if not spark
        return

      handle.stop()
      ts.State.showSpark.set spark

  setProject: (project_name) ->
    if not project_name
      project_name = '全部'

    type = ts.State.showContent.get()
    this.navigate "/projects/#{project_name}/#{type}", true
    amplify.store('project', project_name)

  setSpark: (id) ->
    this.navigate("/sparks/#{id}", true)



Router = new TsRouter

Meteor.startup ->
  Backbone.history.start pushState: true

