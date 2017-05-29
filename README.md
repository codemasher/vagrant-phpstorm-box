# codemasher/vagrant-phpstorm-box

<p style="text-align: center;">
	<img alt="vagrant-phpstorm-box" src="https://raw.githubusercontent.com/codemasher/vagrant-phpstorm-box/master/storage/phpinfo.png">
</p>

A testing environment for PHPStorm projects (based on [laravel/homestead](https://github.com/laravel/homestead)).

## Features
- Apache/PHP 7.1
  - libsodium
  - ImageMagick
  - Redis
  - Memcached
  - APCu
- Databases with PHP extension:
  - MySQL
  - Postgres
  - SQLite
  - Firebird (don't ask.)

## Requirements
- [PHPStorm](http://www.jetbrains.com/phpstorm/)
- [Vagrant](https://www.vagrantup.com/downloads.html)
  - [bento/ubuntu-16.04](https://atlas.hashicorp.com/bento/boxes/ubuntu-16.04)
  - [landrush](https://github.com/vagrant-landrush/landrush)
  - [vagrant-reload](https://github.com/aidanns/vagrant-reload)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Installation (user/password: vagrant)
- extract the [repo files](https://github.com/codemasher/php-cache/archive/master.zip) to your project's root and open the project in PHPStorm
- change the `VIRTUALBOX_DISPLAY_NAME` in `Vagrantfile`
- run the box (Tools > Vagrant > Up)
- :coffee: :tea: :beer:
- [set up the PHP remote interpreter](https://raw.githubusercontent.com/codemasher/vagrant-phpstorm-box/master/storage/settings-interpreter.png) (Settings > Languages & Frameworks > PHP)
- [configure PHPUnit](https://raw.githubusercontent.com/codemasher/vagrant-phpstorm-box/master/storage/settings-tests.png) (Settings > Languages & Frameworks > PHP > Test Frameworks)
- [configure the remote host](https://raw.githubusercontent.com/codemasher/vagrant-phpstorm-box/master/storage/settings-deployment.png)
- [configure MySQL](https://raw.githubusercontent.com/codemasher/vagrant-phpstorm-box/master/storage/settings-mysql.png)
- [configure Postgres](https://raw.githubusercontent.com/codemasher/vagrant-phpstorm-box/master/storage/settings-postgres.png)
- use the box!
  - `/public` -> [http://phpstorm.box](http://phpstorm.box) or [http://localhost:8000](http://localhost:8000)
  - no need for a local `PHPUnit` (except... WTB PHPUnit stubs!)
  
## TODO
- [Apache http/2](https://www.digitalocean.com/community/questions/enable-http2-in-apache-on-ubuntu-16-04) (Apache crashes)
- fix FirebirdWebAdmin config (binaries)
- PHP extensions?