# Class: appliance_components::tomcat
#
# Requires: nothing
#
class appliance_components::tomcat {
  include appliance_components::java
  include ::tomcat
  
  package { 'tomcat8':
    ensure => installed,
  }
	  
  service { 'tomcat8':
	ensure    => running,
	enable    => true,
	subscribe => Package['tomcat8'],
  }
}
