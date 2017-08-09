# Class: appliance_components::apache
#
# This class installs and configures Apache. SSL is configured with a
# self-signed certificate. All traffic is redirected to HTTPS.
#
# Requires: nothing
#
class appliance_components::apache {
  include ::apache
  include ::apache::mod::ssl
  include ::apache::mod::proxy
  include ::apache::mod::proxy_http
  apache::mod { 'proxy_ajp': }
  apache::mod { 'rewrite': }

  case $lsbdistcodename {
    xenial: {
      exec { "make-ssl-cert generate-default-snakeoil --force-overwrite":
        path => ["/usr/sbin", "/bin", "/usr/bin"]
      }
      file { '/etc/apache2/conf-available/redirect-ssl.conf':
        ensure  => present,
        source  => 'puppet:///modules/appliance_components/redirect-ssl.conf',
        require => [
          Package['apache2'],
        ],
        notify  => Service['apache2'],
      }
    }
	
    default: {
      file { '/etc/apache2/sites-enabled/default-ssl':
        ensure  => link,
        target  => '/etc/apache2/sites-available/default-ssl',
        require => [
          Package['apache2'],
          Package['ssl-cert'],
        ],
        notify  => Service['apache2'],
      }
      file { '/etc/apache2/conf.d/redirect-ssl.conf':
        ensure  => present,
        source  => 'puppet:///modules/appliance_components/redirect-ssl.conf',
        require => [
          Package['apache2'],
        ],
        notify  => Service['apache2'],
      }	
    }
  }

  package { 'ssl-cert':
    ensure => installed,
  }
}
