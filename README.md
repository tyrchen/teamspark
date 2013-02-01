Teamspark
=========

## What is Teamspark?

Teamspark is a clean and simple project/task management tool. It enables everyone within the team to capture inspiration, manage tasks, track the progress and communicate freely.

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

## More Information

For more information, please visit: http://tyrchen.github.com/teamspark.
