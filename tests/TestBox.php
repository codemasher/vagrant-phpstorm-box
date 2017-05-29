<?php
/**
 * Class TestBox
 *
 * @filesource   TestBox.php
 * @created      28.05.2017
 * @package      chillerlan\PHPStormBoxTest
 * @author       Smiley <smiley@chillerlan.net>
 * @copyright    2017 Smiley
 * @license      MIT
 */

namespace chillerlan\PHPStormBoxTest;


use PHPUnit\Framework\TestCase;

class TestBox extends TestCase{

	public function testLibSodium(){
		$this->assertTrue(strpos(\Sodium\version_string(),'1.0.1') === 0);
	}

	public function testImagick(){
		$this->assertTrue(strpos(\Imagick::getVersion()['versionString'],'ImageMagick') === 0);
	}

	public function testRedis(){
		$redis = new \Redis();
		$redis->connect('127.0.0.1', 6379);

		$info = $redis->info();

		$this->assertTrue(isset($info['redis_version']));
		$this->assertTrue(strpos($info['redis_version'],'3.2') === 0);
	}

	public function testMemcached(){
		$memcached = new \Memcached;
		$memcached->addServer('localhost', 11211);

		$info = $memcached->getVersion();

		$this->assertTrue(isset($info['localhost:11211']));
		$this->assertTrue(strpos($info['localhost:11211'],'1.4') === 0);
	}

	public function testAPCU(){
		$info = apcu_cache_info();

		$this->assertTrue(isset($info['start_time']));
	}

	public function testFirebird(){
		$db = new \PDO('firebird:dbname=/vagrant/storage/dbtest.fdb', 'SYSDBA', 'masterkey');

		$this->assertTrue(strpos($db->getAttribute(\PDO::ATTR_SERVER_INFO),'Firebird') !== false);
	}

	public function testSQLite(){
		$db = new \PDO('sqlite:/vagrant/storage/dbtest.sqlite', 'SYSDBA', 'masterkey');

		$this->assertTrue(strpos($db->getAttribute(\PDO::ATTR_CLIENT_VERSION),'3.') !== false);

		$db = new \SQLite3('/vagrant/storage/dbtest.sqlite');

		$this->assertTrue(strpos(\SQLite3::version()['versionString'],'3.') === 0);
	}

	public function testPostgres(){
		$db = new \PDO('pgsql:host=localhost;port=5432;dbname=vagrant', 'vagrant', 'vagrant');
		$this->assertTrue(strpos($db->getAttribute(\PDO::ATTR_SERVER_INFO),'PID:') !== false);

		$db = pg_connect("host='localhost' port='5432' dbname='vagrant' user='vagrant' password='vagrant' options='--client_encoding=UTF8'");
		$this->assertTrue(isset(pg_version($db)['client']));
	}

}
