#
# == Class: simple_jail_user::params
#
# Configuration for the simple_jail_user module. Do not use this class directly.
#

class simple_jail_user::params {

    case $::operatingsystem {
        /(?i)(Debian|RedHat|CentOS|Ubuntu)/: {
        	
        	$home_dir			= "/home"
        	$bash_bin   		= "/bin/bash"
			$rbash_bin  		= "/bin/rbash"
        	$openssl    		= "openssl"
        	$passwd     		= "passwd"
        	$tr					= "tr"
        	$password_min_age 	= "0"
        
        }
        default: {
            fail( "Unsupported platform: ${::operatingsystem}" )
        }
    }

}        