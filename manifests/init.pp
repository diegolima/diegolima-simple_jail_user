#-------------------------------------------------------
# $Date: 2013-11-27 08:03:15 +0000 (Wed, 27 Nov 2013) $
# $Revision: 147 $
# $Author: rikih.gunawan $
# $Id: init.pp 147 2013-11-27 08:03:15Z rikih.gunawan $
#-------------------------------------------------------

$bash_bin = "/bin/bash"
$rbash_bin = "/bin/rbash"

class simple_jail_user ($user_data) {

	define foo($password,$commands,$home_dir) {

  		$bin_dir  = "$home_dir/$name/bin"
  		$home_dir2 = "$home_dir/$name"
		#notify {"User=$name home=$home_dir2 pass=$password cmd=$commands" : }

  		# change array element /home/user/bin::/sbin/ifconfig
  		$cmd2     = regsubst($commands,'(^/+)',"${bin_dir}::\0",'G')
  		$cmd3     = regsubst($cmd2,'(^/+)',",\0",'G')
	
  		# create symlink
		createSymlink { $cmd2: }

	}

	define createSymlink () {



  		# split array element /home/user/bin::/sbin/ifconfig
  		$tmp = split($name,'::')
  		$cmd = "${tmp[1]}"

  		# get basename of executable file /sbin/ifconfig => ifconfig
  		$bin = inline_template("<%= File.basename('${cmd}') %>")
  		$exec = "${tmp[0]}/${bin}"
  		$target = "${tmp[1]}"
notify {"EXEC=$exec - $target": }
	}

		/*
  		file { "${exec}":
    			ensure => link,
    			owner  => 'root',
    			group  => 'root',
    			mode   => '0777',
    			target => "${target}",
  		} 

	}
*/
	create_resources(foo, $user_data)

}

/*
define simple_jail_user::parseUser ($home_dir, $cmd) {
  
  $bin_dir  = "$home_dir/$name/bin"
  $home_dir = "$home_dir/$name"

  # change array element /home/user/bin::/sbin/ifconfig
  $cmd2     = regsubst($cmd,'(^/+)',"${bin_dir}::\\0",'G')

  # create symlink
  createSymlink { $cmd2: }

}
*/

define cleanUpHomeDir ($home_dir) {
  
  $unneeded_files = ["$home_dir/$name/.bash_logout", "$home_dir/$name/.bash_profile", "$home_dir/$name/.bashrc"]
  $home_dir = "$home_dir/$name"
  $bin_dir = "$home_dir/$name/bin"

  file { $unneeded_files: ensure => absent, }

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
    ensure  => file,
    owner   => 'root',
    group   => "${name}",
    mode    => '0750',
    content => template("simple_jail_user/profile.erb"),
  }

  file { "${home_dir}/.bash_history":
    ensure => file,
    owner  => $name,
    group  => $name,
    mode   => '0600',
  }

}

define createUser ($home_dir = "/home") {

  user { $name:
    ensure           => present,
    comment          => "Simple jail user $name",
    managehome       => true,
    home             => "${home_dir}/${name}",
    password         => generate($bash_bin, '-c', "echo ${password} | openssl passwd -1 -stdin | tr -d '\n'"),
    password_min_age => '0',
    shell            => $bash_bin,
    require          => [ File[$rbash_bin], File[$home_dir] ],
  }

}

/*

define simple_jail_user::foo($password,$commands,$home_dir) {	
  
  notify {"User=$name home=$home_dir pass=$password cmd=$commands" : }

  simple_jail_user::parseUser ($home_dir, $commands) 

}
*/

/*
class simple_jail_user ($user_data) {

create_resources(simple_jail_user::foo, $user_data)

  file { $rbash_bin:
    ensure => link,
    target => $bash_bin,
    owner  => 'root',
    group  => 'root',
    mode   => '0777',
  }

  file { $home_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  cleanUpHomeDir { $username:
    home_dir => $home_dir,
    require  => User[$username],
  }

  parseUser { $username:
    home_dir => "${home_dir}",
    cmd      => $cmd,
    require  => CleanUpHomeDir[$username],
  }

}
*/


