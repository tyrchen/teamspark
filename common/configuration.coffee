if Meteor.is_server
  weibo_service =
    service: "weibo"
    clientId: "2737982731" # please replace this with your own id
    secret: "c67378e5e2d1f349397eb15f34e7f889" # please replace this with your own secret

if Meteor.is_client
  Meteor.startup ->
    filepicker.setKey 'An2MQKIF1S7i1SF2xa3e0z' #Please change this to your own filepicker.io api key (you will have 5000 files per month for free)