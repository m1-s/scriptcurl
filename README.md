# scriptcurl

Opens a website, executes arbitrary javascript and returns the console log.

Uses Selenium, Nix and bash.

Example:
```bash
$ nix run github:m1-s/scriptcurl -- "https://google.de" "console.log('hello world')"
[0303/104437.292881:INFO:CONSOLE(3)] "hello world", source:  (3)
```
