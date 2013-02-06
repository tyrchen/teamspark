![Teamspark](/public/favicon.png) Teamspark
=========

## What is Teamspark?

Teamspark is a clean and simple project/task management tool. It enables everyone within the team to capture inspiration, manage tasks, track the progress and communicate freely.

### Online Demo
we provided an online demo for teamspark for you to test: http://ts-demo.tchen.me. 

We provided two accounts:
admin user: admin/teamspark
normal user: demo/teamspark

You can login with these 2 users in different browsers (suggest chrome/firefox). If you want to register your own, you should use admin user to approve the new user.

## Installation

### MongoDB

[Mongodb](http://www.mongodb.org/) shall be installed as a database service for Teamspark. To install it:

Ubuntu:
```
$ sudo apt-get install mongodb
```

OSX with homebrew:
```
$ brew install mongodb
```

For windows and other platforms, please refer to the related documents.

### Meteor

Teamspark uses [meteor](http://meteor.com) framework. To install meteor:

```
$ curl https://install.meteor.com | /bin/sh
```

Meanwhile, you can clone/fork the code to your local folder. When meteor/mongodb installation finished, you can run it by:
```
$ cd teamspark
$ meteor
```

> Note: for chinese user, please checkout to chinese branch so that you could have a familiar user interface.

Then teamspark service will be started at port 3000. You can visit http://localhost:3000 to see the demo.

## Configuration

If you intend to use it in your own projects, make sure you configure the proper keys. Open teamspark/common/configuration.coffee, replace the weibo app key/secret and filepicker.io api key with your own ones.

## License

Teamspark is licensed under the MIT License.

## Contributors

Teamspark is designed and implemented by @tyrchen. For more information about the author, please visit: http://tchen.me/pages/aboutme.html

Teamspark logo is contributed by @0065paula of [Pyology](http://pyology.com/).

## More Information

For more information, please visit: http://tyrchen.github.com/teamspark.
