#
# == Class: simple_jail_user::params
#
# Configuration for the simple_jail_user module. Do not use this class directly.
#
# === Authors
#
# Rikih Gunawan <rikih dot gunawan at gmail.com>
#
# === Copyright
#
# Copyright 2014 Rikih Gunawan
#

class simple_jail_user::params {

    case $::operatingsystem {
        /(?i)(Debian|RedHat|CentOS|Ubuntu)/: {
        	
        	$home_dir		= "/home"
        	$bash_bin   		= "/bin/bash"
		$rbash_bin  		= "/bin/rbash"
        	$openssl    		= "openssl"
        	$passwd     		= "passwd"
        	$tr			= "tr"
        	$password_min_age 	= "0"
		$user_group		= "root"
        
        }
        default: {
            fail( "Unsupported platform: ${::operatingsystem}" )
        }
    }

}        
