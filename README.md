# WeChat Helper on Mac OS X

## Synopsis

This is an experimental WeChat Helper created by Tison\<wander4096@gmail.com>.

See more on [project page](https://tisonkun.github.io/WeChatHelper).

It provides several enhancements of WeChat, including prevent revoking mesage, auto login and auto reply.

You can download dmg file in release page and easy install it, or `git clone` this repo and developing by your self.

## Development

Open project in Xcode, build and run. Make sure you have permission on WeChat folder. If not, run `sudo chmod -R 777 /Applications/WeChat.app`.

To uninstall WeChat Helper, run `Release/UNINSTALL`.

## Release

To make a release, make sure you have `appdmg` installed(it is an app on npm), then `cd` to Release/ and run `appdmg package.json WeChatHelper.dmg`.

## License

See [LICENSE](LICENSE).
