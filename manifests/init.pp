#-------------------------------------------------------
# $Date: 2013-11-27 08:03:15 +0000 (Wed, 27 Nov 2013) $
# $Revision: 147 $
# $Author: rikih.gunawan $
# $Id: init.pp 147 2013-11-27 08:03:15Z rikih.gunawan $
#-------------------------------------------------------

define createSymlink($homebin, $cmd) {

	file { "${homebin}/${cmd}":
		ensure => link,
		target => "/sbin/$cmd",
		owner  => 'root',
		group  => 'root',
		mode   => '0777',
	}
}

define cleanUpHomeDir($homedir) {
	$unneeded_files = [ "$homedir/$name/.bash_logout", "$homedir/$name/.bash_profile", "$homedir/$name/.bashrc" ]
	$bin_dir = "$homedir/$name/bin"
	$home_dir = "$homedir/$name"

	file { $unneeded_files: 
		ensure => absent,
	}

	file { $bin_dir:
		ensure => directory,
		owner  => 'root',
		group  => 'root',
		mode   => '0755',
	}

	file { $home_dir:
		ensure => directory,
		owner  => 'root',
		group  => "${name}",
		mode   => '2070',
	} 

	file { "${home_dir}/.profile":
		ensure => file,
		owner  => 'root',
		group  => "${name}",
		mode   => '0750',
		source => 'puppet:///modules/simple_jail_user/profile',
	}

	file { "${home_dir}/.bash_history":
		ensure => file,
		owner  => $name,
		group  => $name,
		mode   => '0600',
	}

}

class simple_jail_user( 
	$username,
	$password,
	$homedir="/home"
	){

	$bashbin="/bin/bash"
	$rbashbin="/bin/rbash"

	notify { "Creating CDM Jail Users..": }
	file { $rbashbin:
		ensure => link,
		target => $bashbin,
		owner  => 'root',
		group  => 'root',
		mode   => '0777',
	}

	notify { 'Creating user..': }
	user { $username:
  		ensure           => present,
  		comment          => "Simple jail user $username",
		managehome	 => true,
  		password         => generate($bashbin, '-c', "echo ${password} | openssl passwd -1 -stdin | tr -d '\n'"),
 	 	password_min_age => '0',
  		shell            => $bashbin,
		require 	 => File[$rbashbin],	
	}

	notify { 'Cleaning up home dir..': }
	cleanUpHomeDir { $username: 
		homedir => $homedir,
		require => User[$username],
	}

	notify { 'Creating symlink..': }
	createSymlink { $username:
		homebin => $homebin, 
		cmd     => ["ifconfig","ip"],
		require => CleanUpHomeDir[$username],
	}
}



