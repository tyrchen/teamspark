_.extend Template.iphone,
  sparks: ->
    Sparks.find {owners: Meteor.userId}, {sort: updatedAt: -1}