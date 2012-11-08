ts = ts || {}
ts.tags = ts.tags || {}
ts.tags.createOrUpdate = (name, projectId, value=1) ->
  if not name
    return

  user = Meteor.user()
  tag = Tags.findOne {name: name, teamId: user.teamId, projectId: projectId}
  if tag
    Tags.update tag._id, $inc: sparks: value
  else
    Tags.insert
      name: name
      teamId: user.teamId
      projectId: projectId
      createdAt: ts.now()
      sparks: 1