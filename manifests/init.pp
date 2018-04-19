#
# == Class: simple_jail_user
#
# Init class for the simple_jail_user module.
#
# === Authors
#
# Rikih Gunawan <rikih dot gunawan at gmail.com>
#
# === Copyright
#
# Copyright 2014 Rikih Gunawan
#

class simple_jail_user (
    ) inherits simple_jail_user::params
  {

  file { "${simple_jail_user::params::rbash_bin}" :
    ensure => link,
    target => $bash_bin,
    owner  => 'root',
    group  => "${simple_jail_user::params::user_group}",
    mode   => '0777',
  }

  define createjailuser(
    $is_hash,
    $password,
    $commands,
    $home_dir=$simple_jail_user::params::home_dir
    ) {

    $bin_dir  = "${home_dir}/${name}/bin"

    # change array element /home/user/bin::/sbin/ifconfig
    $cmd2     = regsubst($commands,'(^/+)',"${bin_dir}::\\0",'G')

    simple_jail_user::createuser { "$name":
      is_hash   => $is_hash,
      password => $password,
      home_dir => $home_dir,
      commands => $commands
    }

    simple_jail_user::cleanuphomedir { "${name}":
      home_dir => $home_dir
    }

    # create symlink
    simple_jail_user::createsymlink { $cmd2:
    }

  }

  define createuser (
    $is_hash,
    $password,
    $commands,
    $home_dir=$simple_jail_user::params::home_dir
    ) {

    if $simple_jail_user::users_group == "" {
      $users_group = $name
    } else {
      $users_group = $simple_jail_user::users_group
    }

    exec { "${home_dir}":
      cwd     => "/tmp",
      path    => ["/bin"],
      command => "mkdir -p ${home_dir}",
      creates => "${home_dir}",
    }

    file { "${home_dir}":
      ensure => directory,
      owner  => 'root',
      group  => "${simple_jail_user::params::user_group}",
      mode   => '0755',
      require => Exec["${home_dir}"],
    }

    file { "${home_dir}/${name}":
      ensure  => directory,
      owner   => 'root',
      group   => "${users_group}",
      mode    => '2070',
      require => File["${home_dir}"],
    }

    file { "${home_dir}/${name}/.profile":
      ensure  => file,
      owner   => 'root',
      group   => "${users_group}",
      mode    => '0750',
      content => template("simple_jail_user/profile.erb"),
      require => File["${home_dir}/${name}"],
    }

    if $is_hash == "false" {
      $user_pass = generate($simple_jail_user::params::bash, '-c', "echo ${password} | ${simple_jail_user::params::openssl} ${simple_jail_user::params::passwd} -1 -stdin | ${simple_jail_user::params::tr} -d '\n' ")
    } else {
      $user_pass = $password
    }

    if $::operatingsystem == "OpenBSD" {
      user { "${name}":
        ensure           => present,
        comment          => "Simple jail user $name",
        managehome       => false,
        home             => "${home_dir}/${name}",
        password    => "${user_pass}",
        shell            => $simple_jail_user::params::rbash_bin,
        require          => [
              File[$simple_jail_user::params::rbash_bin],
                ],
        notify      => [
              File["${home_dir}/${name}"],
              File["${home_dir}/${name}/.profile"],
                ],
      }

      if $is_hash == "false" {
        $command = "${simple_jail_user::params::usermod} -p `echo '${password}' | ${simple_jail_user::params::encrypt} -b 6` ${name}"
      } else {
        $command = "${simple_jail_user::params::usermod} -p '${password}' ${name}"
      }

      exec {"chpasswd-${name}":
        cwd      => "/tmp",
        path     => ['/usr/bin','/usr/sbin'],
        user     => 'root',
        command  => "${command}",
        require  => User["${name}"],
      }

    } else {
                        user { "${name}":
                                ensure           => present,
                                comment          => "Simple jail user $name",
                                managehome       => false,
                                home             => "${home_dir}/${name}",
                                password         => "${user_pass}",
                                password_min_age => $simple_jail_user::params::password_min_age,
                                shell            => $simple_jail_user::params::rbash_bin,
                                require          => [
                                                        File[$simple_jail_user::params::rbash_bin],
                                                ],
                                notify           => [
                                                        File["${home_dir}/${name}"],
                                                        File["${home_dir}/${name}/.profile"],
                                                ],
                        }
    }
  }

  define createsymlink () {

    # split array element /home/user/bin::/sbin/ifconfig
    $tmp = split($name,'::')
    $cmd = "${tmp[1]}"

    # get basename of executable file /sbin/ifconfig => ifconfig
    $bin = inline_template("<%= File.basename('${cmd}') %>")
    $exec = "${tmp[0]}/${bin}"
    $target = "${tmp[1]}"

    file { "${exec}":
      ensure => link,
      owner  => 'root',
      group  => "${simple_jail_user::params::user_group}",
      mode   => '0777',
      target => "${target}",
    }

  }

  define cleanuphomedir ($home_dir) {

      $unneeded_files = ["$home_dir/$name/.bash_logout", "$home_dir/$name/.bash_profile", "$home_dir/$name/.bashrc"]
      $home_dir2 = "$home_dir/$name"
      $bin_dir = "$home_dir/$name/bin"

      file { $unneeded_files:
      ensure => absent,
    }

      file { $bin_dir:
      ensure => directory,
      owner  => 'root',
      group  => "${simple_jail_user::params::user_group}",
      mode   => '0755',
      }

      file { "${home_dir2}/.bash_history":
      ensure => file,
      owner  => $name,
      group  => "${simple_jail_user::params::user_group}",
      mode   => '0600',
    }

  }
}
