# rikih-simple-jail-user

This is an update of the rikihg/rikih-simple_jail_user module which should run on newer puppet versions. Aside from
a couple of changes all credit goes to him.

Puppet Module to create simple jail user using restricted shell using bash (rbash) on Linux.
How it's works, we create the user and set the shell pointing to rbash and then create symlink of commands into $HOME/bin/ and then limit the environment variable PATH only to $HOME/bin.

## What is restricted shell ?

The Restricted Shell (http://www.gnu.org/software/bash/manual/html_node/The-Restricted-Shell.html)

## Limitation

* Currently only tested for CentOS/RedHat 5.x/6.x, Ubuntu 12.x (precise), Debian 7.x (wheezy), Fedora 18, OpenBSD 5.0

* The command that you limit does not have any dependency with other command and able to run with PATH=$HOME/bin only.

```linux
  e.g:
      how to check if the command is able to run on restricted bash ?
      # export PATH=/bin
      # ./date
  Sun Apr 20 23:28:49 SGT 2014
```

## How to use

* is_hash = true | false : if you're using hash on the password, you must set it to "true" else set it to "false"

* home_dir : User home directory location

* password : User password, it can be using clear text (is_hash = false) or encrypted text (is_hash = true)

* commands : List of commands that you want to allow for the user

```puppet
  class {'simple_jail_user': }
  simple_jail_user::createjailuser { 'user1':
    is_hash         => 'false',
    home_dir        => '/home',
    password        => 'password',
    commands        => ['/path/command1','/path/command2']
  }
  simple_jail_user::createjailuser { 'user2':
    is_hash    => 'true',
    home_dir   => '/home',
    password        => 'password',
    commands        => ['/path/command1','/path/command2','/path/command3']
  }
```

Go to the puppet modules dir and clone the git repo

```linux
# cd /etc/puppet/modules

# git clone https://github.com/rikihg/rikih-simple_jail_user.git
Cloning into 'rikih-simple_jail_user'...
remote: Reusing existing pack: 80, done.
remote: Counting objects: 9, done.
remote: Compressing objects: 100% (9/9), done.
remote: Total 89 (delta 1), reused 0 (delta 0)
Unpacking objects: 100% (89/89), done.

# vim /etc/puppet/manifests/site.pp
```

For example we want to create user "riq" with password "password" and limit this user only able to run command "/sbin/ifconfig" and "/sbin/ip" only
also user create user "john" with password and limit this user only able to run command "/usr/bin/telnet", "/bin/traceroute" and "/usr/bin/ftp" only on Linux Operating System.
To do above requirement, change the site.pp like below.

Below are how to generate password hash for Linux and OpenBSD

```linux
On Linux, to generate password hash
# echo password | openssl  passwd -1 -stdin
$1$d4C/wWcn$r2eRLmmVJY3yNDsRhcKVW

On OpenBSD 5.0
# echo password | encrypt -b 6
$2a$06$4KQ3t/AFoVn2Sw.9s1WROuERcY2cDVq6L7k.qIgHID020YqMtCaca
```

```puppet
node "kiwi" {

  class {'simple_jail_user': }
  simple_jail_user::createjailuser { 'riq':
    is_hash         => 'false'
    home_dir        => '/home',
    password        => 'password',
    commands        => ['/sbin/ifconfig','/sbin/ip']
  }
  simple_jail_user::createjailuser { 'john':
    is_hash         => 'true',
    home_dir   => '/opt/home', 
    password        => '$1$d4C/wWcn$r2eRLmmVJY3yNDsRhcKVW', 
    commands        => ['/usr/bin/telnet','/bin/traceroute','/usr/bin/ftp']
  }
}
```

Run puppet on the client and verify it.

```linux
# puppet agent --test

Below are the home dir and files created for each user

# ls -alhR /home/riq/
/home/riq/:
total 20K
d---rws--- 3 root riq  4.0K Apr 20 15:41 .
drwxr-xr-x 4 root root 4.0K Apr 20 15:41 ..
-rw------- 1 riq  riq     0 Apr 20 15:41 .bash_history
drwxr-xr-x 2 root root 4.0K Apr 20 15:41 bin
-rwxr-x--- 1 root riq   317 Apr 20 15:41 .profile

/home/riq/bin:
total 8.0K
drwxr-xr-x 2 root root 4.0K Apr 20 15:41 .
d---rws--- 3 root riq  4.0K Apr 20 15:41 ..
lrwxrwxrwx 1 root root   14 Apr 20 15:41 ifconfig -> /sbin/ifconfig
lrwxrwxrwx 1 root root    8 Apr 20 15:41 ip -> /sbin/ip

# ls -alhR /opt/home/
/opt/home/:
total 16K
drwxr-xr-x 3 root root 4.0K Apr 20 15:41 .
drwxr-xr-x 4 root root 4.0K Apr 20 15:41 ..
d---rws--- 3 root john 4.0K Apr 20 15:41 john

/opt/home/john:
total 16K
d---rws--- 3 root john 4.0K Apr 20 15:41 .
drwxr-xr-x 3 root root 4.0K Apr 20 15:41 ..
-rw------- 1 john john    0 Apr 20 15:41 .bash_history
drwxr-xr-x 2 root root 4.0K Apr 20 15:41 bin
-rwxr-x--- 1 root john  329 Apr 20 15:41 .profile

/opt/home/john/bin:
total 8.0K
drwxr-xr-x 2 root root 4.0K Apr 20 15:41 .
d---rws--- 3 root john 4.0K Apr 20 15:41 ..
lrwxrwxrwx 1 root root   12 Apr 20 15:41 ftp -> /usr/bin/ftp
lrwxrwxrwx 1 root root   15 Apr 20 15:41 telnet -> /usr/bin/telnet
lrwxrwxrwx 1 root root   15 Apr 20 15:41 traceroute -> /bin/traceroute

Test if the jail user only able to run commands that you specified only

# ssh john@server1
john@server1's password: 
Available commands:
* telnet
* traceroute
* ftp

$ ftp
ftp> exit
$ telnet
telnet> quit
# ping
-rbash: ping: command not found
$ ifconfig
-rbash: ifconfig: command not found
$ export PATH=/sbin/
-rbash: PATH: readonly variable
$ /sbin/ifconfig
-rbash: /sbin/ifconfig: restricted: cannot specify `/' in command names


# ssh riq@server1
riq@server1's password: 
Available commands:
* ifconfig
* ip

$ traceroute
-rbash: traceroute: command not found
$ ping
-rbash: ping: command not found
$ ip
Usage: ip [ OPTIONS ] OBJECT { COMMAND | help }
       ip [ -force ] [-batch filename
where  OBJECT := { link | addr | addrlabel | route | rule | neigh | ntable | tunnel |
                   maddr | mroute | monitor | xfrm }
       OPTIONS := { -V[ersion] | -s[tatistics] | -r[esolve] |
                    -f[amily] { inet | inet6 | ipx | dnet | link } |
                    -o[neline] | -t[imestamp] }

```

## Help

Please log tickets and issues at our page https://github.com/diegolima/rikih-simple_jail_user/issues
or contact me at diego at diego dot lima dot org.  The original author can be reached at rikih dot gunawan at gmail dot com

## Note
No responsibility for any damages relating to its use. Use at your own risk.
