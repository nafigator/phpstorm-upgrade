[![GitHub license][License img]][License src]

# phpstorm-upgrade
Bash script for [PhpStorm®] upgrade.

### Requirements
* bash
* curl
* tar
* grep && egrep

Tested under Linux Debian only. Feel free to [create issue] if there is problems
under other *n[iu]x OS or if you have idea how to improve script.

### Underhood
By default script downloads and unpack PhpStorm archive to
_**~/.local/share/phpstorm/PhpStorm-n.n.n**_ direcrory. Then creates
launcher-link _**~/bin/phpstorm**_. If you want to install PhpStorm in other
place, modify **PHPSTORM_DIR** and **BINARY_DIR** variables. For example
if you want such install sheme:
```bash
/usr/local/
          /bin/phpstorm                   # link
          ...
          /share/phpstorm/PhpStorm-n.n.n/ # program dir
```
Modify variables to:
```bash
BINARY_DIR='/usr/local/bin'
PHPSTORM_DIR='/usr/local/share/phpstorm'
```

  [License img]: https://img.shields.io/badge/license-BSD3-brightgreen.svg
  [License src]: https://tldrlegal.com/license/bsd-3-clause-license-(revised)
  [create issue]: https://github.com/nafigator/phpstorm-upgrade/issues/new/
  [PhpStorm®]: https://www.jetbrains.com/phpstorm/ "PhpStorm IDE"
