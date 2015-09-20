[![GitHub license][License img]][License src]

# phpstorm-upgrade
Bash script for [PhpStorm®] upgrade

### Requirements
* bash
* curl
* tar
* grep && egrep

Tested under Linux Debian only. Feel free to [create issue] if there is problems
under other *n[iu]x OS or if you have idea how to improve script.

### Underhood
By default script downloads and unpack PhpStorm archive to
`~/.local/share/phpstorm/PhpStorm-n.n.n` direcrory. Then creates
launcher-link `~/bin/phpstorm`. If you want to install PhpStorm in other
place, modify `PHPSTORM_DIR` and `BINARY_DIR` variables.

  [License img]: https://img.shields.io/badge/license-BSD3-brightgreen.svg
  [License src]: https://tldrlegal.com/license/bsd-3-clause-license-(revised)
  [create issue]: https://github.com/nafigator/phpstorm-upgrade/issues/new/
  [PhpStorm®]: https://www.jetbrains.com/phpstorm/
