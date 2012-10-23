_.extend Template.iphone,
  teamName: -> ts.currentTeam()?.name
  sparks: ->
    Sparks.find {owners: Meteor.userId()}, {sort: updatedAt: -1}