_.extend Template.iphone,
  sparks: ->
    Sparks.find {userId: Meteor.userId}, {sort: updatedAt: -1}