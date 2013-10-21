if Meteor.isServer
  @weibo_service =
    service: "weibo"
    clientId: "2737982731" # please replace this with your own id
    secret: "c67378e5e2d1f349397eb15f34e7f889" # please replace this with your own secret

  @github_service =
    service: "github"
    clientId: "70316cc48b0cc9a6fa32"
    secret: "c30d604147e1d26e3b06d49e7b63281bcaa26375"

if Meteor.isClient
  Meteor.startup ->
    filepicker.setKey 'An2MQKIF1S7i1SF2xa3e0z' #Please change this to your own filepicker.io api key (you will have 5000 files per month for free)