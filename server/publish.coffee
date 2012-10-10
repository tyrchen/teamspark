# team = { _id: uuid, name: '途客圈战队', author: username, members: [username1, username2, ... ]}
Teams = new Meteor.Collection 'teams'
Meteor.publish 'team', (id) ->
  return Teams.findOne _id: id

# project = { _id: uuid, name: 'cayman', description: 'cayman is a project', parent: null, }

# spark = {
# _id: uuid, type: 'idea', author: uuid, receivers: [username1, username2, ...], auditTrails: [],
# pm: username, ued: username, fe: username, be: username, qa: username,
# title: 'blabla', content: 'blabla', priority: 1, supporters: [username1, username2, ...],
# progress: 10, project: ['cayman', ...], tags: [''], deadline: Date(), created: Date()
# }

###
story =
  id: uuid
  title: 'This is a story'
  created_at: new Date()
  team: 'tukeQ'
###
Stories = new Meteor.Collection "stories"
Meteor.publish 'stories', (team_name) ->
  return Stories.find team: team_name


###
ttodo =
  id: uuid
  title: 'Need to do this'
  author: 'Tyr Chen'
  assignee: 'Tyr Chen'
  team: 'Tyr Chen'
  created_at: new Date()
  category: 'ttodo' # 'doing', 'done', 'verified'
###

Todos = new Meteor.Collection "todos"
Meteor.publish 'todos', (team_name) ->
  return Todos.find  team: team_name, sort: 'created_at': -1


# access control
Meteor.startup ->
  isStaff = (userId, teams) ->
    console.log userId, articles
    return true

  canModify = (userId, articles) ->
    _.all articles, (article) ->
      article.author is userId

  Articles.allow
    insert: isStaff
    update: canModify
    remove: canModify

  Topics.allow
    insert: isStaff
    update: isStaff


# bootstrap
# if database is empty, on startup, create some basic data

if Topics.find().count() is 0
  data = [
    {name: '代码人生', description: ''}
    {name: '创业历程', description: ''}
    {name: '探索发现', description: ''}
    {name: '奇思妙想', description: ''}
    {name: '作品大全', description: ''}
    {name: '自我介绍', description: ''}
  ]
  now = (new Date()).getTime()
  for item in data
    Topics.insert
      name: item.name
      description: item.description
      articles: 0
      created_at: now
