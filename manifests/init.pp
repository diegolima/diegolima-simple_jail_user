#-------------------------------------------------------
# $Date: 2013-11-27 08:03:15 +0000 (Wed, 27 Nov 2013) $
# $Revision: 147 $
# $Author: rikih.gunawan $
# $Id: init.pp 147 2013-11-27 08:03:15Z rikih.gunawan $
#-------------------------------------------------------

define createSymlink {

	file { "/home/${name}/bin/ifconfig":
		ensure => link,
		target => '/sbin/ifconfig',
		owner  => 'root',
		group  => 'root',
		mode   => '0777',
	}

        file { "/home/${name}/bin/route":
                ensure => link,
                target => '/sbin/route',
                owner  => 'root',
                group  => 'root',
                mode   => '0777',
        }

        file { "/home/${name}/bin/groups":
                ensure => link,
                target => '/usr/bin/groups',
                owner  => 'root',
                group  => 'root',
                mode   => '0777',
        }

        file { "/home/${name}/bin/ls":
                ensure => link,
                target => '/bin/ls',
                owner  => 'root',
                group  => 'root',
                mode   => '0777',
        }

        file { "/home/${name}/bin/sed":
                ensure => link,
                target => '/bin/sed',
                owner  => 'root',
                group  => 'root',
                mode   => '0777',
        }

        file { "/home/${name}/bin/snmpget":
                ensure => link,
                target => '/usr/bin/snmpget',
                owner  => 'root',
                group  => 'root',
                mode   => '0777',
        }

        file { "/home/${name}/bin/snmpwalk":
                ensure => link,
                target => '/usr/bin/snmpwalk',
                owner  => 'root',
                group  => 'root',
                mode   => '0777',
        }

        file { "/home/${name}/bin/ssh":
                ensure => link,
                target => '/usr/bin/ssh',
                owner  => 'root',
                group  => 'root',
                mode   => '0777',
        }

        file { "/home/${name}/bin/telnet":
                ensure => link,
                target => '/usr/bin/telnet',
                owner  => 'root',
                group  => 'root',
                mode   => '0777',
        }

        file { "/home/${name}/bin/traceroute":
                ensure => link,
                target => '/bin/traceroute',
                owner  => 'root',
                group  => 'root',
                mode   => '0777',
        }

	file { "/home/${name}/bin/ping":
		ensure => link,
		target => '/bin/ping',
		owner  => 'root',
		group  => 'root',
		mode   => '0777',
	}

}


define cleanUpHomeDir {

	$unneeded_files = [ "/home/$name/.bash_logout", "/home/$name/.bash_profile", "/home/$name/.bashrc" ]
	$bin_dir = "/home/$name/bin"
	$home_dir = "/home/$name"

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
		source => 'puppet:///modules/cdm_jail_user/profile',
		##target => "${home_dir}/.profile",
	}

	file { "${home_dir}/.bash_history":
		ensure => file,
		owner  => $name,
		group  => $name,
		mode   => '0600',
	}

}

class cdm_jail_user( 
	$username,
	$password = '$1$0t5I3mcB$DQyxLqwNpDUIppY0D7HKa1',
	){
	# default password: Orange365

	notify { "Creating CDM Jail Users..": }

	file { '/bin/rbash':
		ensure => link,
		target => '/bin/bash',
		owner  => 'root',
		group  => 'root',
		mode   => '0777',
	}

	notify { 'Creating user..': }
	user { $username:
  		ensure           => 'present',
  		comment          => $username,
		managehome	 => true,
  		password         => $password,
 	 	password_min_age => '0',
  		shell            => '/bin/rbash',
		require 	 => File['/bin/rbash'],	
	}

	notify { 'Cleaning up home dir..': }
	cleanUpHomeDir { $username: 
		require => User[$username],
	}

	notify { 'Creating symlink..': }
	createSymlink { $username:
		require => CleanUpHomeDir[$username],
	}
}



