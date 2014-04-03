#-------------------------------------------------------
# $Date: 2013-11-27 08:03:15 +0000 (Wed, 27 Nov 2013) $
# $Revision: 147 $
# $Author: rikih.gunawan $
# $Id: init.pp 147 2013-11-27 08:03:15Z rikih.gunawan $
#-------------------------------------------------------

define createSymlink () {
  
  # split array element /home/user/bin::/sbin/ifconfig
  $tmp = split($name, '::')
  $cmd = "${tmp[1]}"

  # get basename of executable file /sbin/ifconfig => ifconfig
  $bin = inline_template("<%= File.basename('${cmd}') %>")
  $exec = "${tmp[0]}/${bin}"
  $target = "${tmp[1]}"

  file { "${exec}":
    ensure => link,
    owner  => 'root',
    group  => 'root',
    mode   => '0777',
    target => "${target}",
  }

}

define parseUser ($homedir, $cmd) {
  
  $bin_dir  = "$homedir/$name/bin"
  $home_dir = "$homedir/$name"

  # change array element /home/user/bin::/sbin/ifconfig
  $cmd2     = regsubst($cmd,'(^/+)',"${bin_dir}::\\0",'G')

  # create symlink
  createSymlink { $cmd2: }

}

define cleanUpHomeDir ($homedir, $cmd) {
  
  $unneeded_files = ["$homedir/$name/.bash_logout", "$homedir/$name/.bash_profile", "$homedir/$name/.bashrc"]
  $home_dir = "$homedir/$name"
  $bin_dir = "$homedir/$name/bin"

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

class simple_jail_user ($username, $password, $cmd, $homedir = "/home") {
  
  $bashbin = "/bin/bash"
  $rbashbin = "/bin/rbash"

  notify { "Creating CDM Jail Users..": }

  file { $rbashbin:
    ensure => link,
    target => $bashbin,
    owner  => 'root',
    group  => 'root',
    mode   => '0777',
  }

  user { $username:
    ensure           => present,
    comment          => "Simple jail user $username",
    managehome       => true,
    password         => generate($bashbin, '-c', "echo ${password} | openssl passwd -1 -stdin | tr -d '\n'"),
    password_min_age => '0',
    shell            => $bashbin,
    require          => File[$rbashbin],
  }

  cleanUpHomeDir { $username:
    homedir => $homedir,
    cmd     => $cmd,
    require => User[$username],
  }

  parseUser { $username:
    homedir => "${homedir}",
    cmd     => $cmd,
    require => CleanUpHomeDir[$username],
  }
  
}
