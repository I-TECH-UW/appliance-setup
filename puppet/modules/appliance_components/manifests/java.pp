# Class: appliance_components::java
#
# Requires: nothing
#
class appliance_components::java {
  include ::java

  case $lsbdistcodename {
    xenial: {
      package { 'maven':
        ensure => installed,
      }
    }
    default: {
      package { 'maven2':
        ensure => installed,
      }
    }
  }
}
