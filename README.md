teamspark
=========

A realtime, simple page application for intra-team communication and collaboration. Could be used for product discussion and/or bug/task tracking.

## Installation

You need to install [meteor](http://meteor.com) first:

```
$ curl https://install.meteor.com | /bin/sh
```

Meanwhile, you can grab the code to your local folder. When meteor installation finished, you can run it by:
```
$ cd teamspark
$ meteor
```

Then teamspark service will be started at port 3000. You can visit http://localhost:3000 to see the demo.

## Configuration

If you intend to use it in your own projects, make sure you configure the proper keys. Open teamspark/common/configuration.coffee, replace the weibo app key/secret and filepicker.io api key with your own ones.

## License

Teamspark is licensed under the MIT License.

## More Information

For more information, please visit: http://tyrchen.github.com/teamspark.
