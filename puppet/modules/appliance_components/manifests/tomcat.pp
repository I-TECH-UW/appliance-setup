# Class: appliance_components::tomcat
#
# Requires: nothing
# This class uses requires extensively to ensure proper 
# order of operation
class appliance_components::tomcat(
  $web_parent_dir = "/usr/share/tomcat8.5", 
  $use_client_certs = false,
  $web_application_name = "OpenELIS",
  $keystore_pass = "changeit",) {
  
  $CATALINA_HOME = "/usr/share/tomcat8.5"
  $CATALINA_BASE = $CATALINA_HOME
  $web_app_dir = "webapplications"
  $auto_deploy = true
  $keystore_file = "${CATALINA_HOME}/.keystore"
  

  include appliance_components::java
  include appliance_components::apache
  
  #install tomcat from source
  tomcat::install { $CATALINA_HOME:
    source_url => 'https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.39/bin/apache-tomcat-8.5.39.tar.gz',
  }

  #set up instance of tomcat
  tomcat::instance { 'tomcat8':
    catalina_home         => $CATALINA_HOME,
    catalina_base         => $CATALINA_BASE,
    user                  => 'tomcat',
    group                 => 'tomcat',
    require               => Tomcat::Install[$CATALINA_HOME],
  }

  #set shutdown command
  tomcat::config::server { 'tomcat8-server':
    catalina_base         => $CATALINA_BASE,
    port                  => '8005',
    shutdown              => 'KillMe',
    require               => Tomcat::Install[$CATALINA_HOME],
  }

  #create http onnector on port 8080
  tomcat::config::server::connector { 'tomcat-http':
    catalina_base         => $CATALINA_BASE,
    port                  => '8080',
    protocol              => 'HTTP/1.1',
    additional_attributes => {
      'redirectPort'        => '8443',
      'connectionTimeout'   => '20000',
      'URIEncoding'         => 'UTF-8',
      'xpoweredBy'          => 'false',
      'server'              => 'tomcat',
      'allowTrace'          => 'false',
      'maxHttpHeaderSize'   => '8192',
    },
    require               => Tomcat::Install[$CATALINA_HOME],
  }

  #create https connector on port 8443
  tomcat::config::server::connector { 'tomcat-https':
    catalina_base         => $CATALINA_BASE,
    port                  => '8443',
    protocol              => 'HTTP/1.1',
    additional_attributes => {
      'connectionTimeout'   => '20000',
      'SSLEnabled'          => 'true',
      'maxThreads'          => '150',
      'scheme'              => 'https',
      'secure'              => 'true',
      'clientAuth'          => "${use_client_certs}",
      'sslProtocol'         => 'TLS',
      'xpoweredBy'          => 'false',
      'server'              => 'tomcat',
      'allowTrace'          => 'false',
      'maxHttpHeaderSize'   => '8192',
      'keystorePass'        => "${keystore_pass}",
      'keystoreFile'        => "${keystore_file}",
    },
    require               => Tomcat::Install[$CATALINA_HOME],
  }
  
  #delete default ajp connector
  tomcat::config::server::connector { 'tomcat-ajp':
    catalina_base         => $CATALINA_BASE,
    connector_ensure      => 'absent',
    port                  => '8009',
    protocol              => 'HTTP/1.1',
    require               => Tomcat::Install[$CATALINA_HOME],
  }
  
  #create host
  tomcat::config::server::host { 'localhost':
    catalina_base         => $CATALINA_BASE,
    app_base              => "${web_parent_dir}/${web_app_dir}",
    additional_attributes => {
      'autoDeploy'          => "${auto_deploy}",
      'deployOnStartup'     => "${auto_deploy}",
    },
    require               => Tomcat::Install[$CATALINA_HOME],
  }

  #Create one context for each app being deployed  
  #tomcat::config::server::context { 'ROOT':
  #  catalina_base         => $CATALINA_BASE,
  #  parent_engine         => 'Catalina',
  #  parent_host           => 'localhost',
  #  doc_base              => 'ROOT',
  #  additional_attributes => {
  #    'path'                => '',
  #    'logEffectiveWebXml'  => 'true',
  #  },
  #  require               => Tomcat::Config::Server::Host['localhost'],
  #}
  
  #create remote address valve in application context
  #tomcat::config::server::valve { 'ROOTRemoteAddrValve':
  #  catalina_base         => $CATALINA_BASE,
  #  class_name            => 'org.apache.catalina.valves.RemoteAddrValve',
  #  parent_host           => 'localhost',
  #  parent_context        => 'ROOT',
  #  additional_attributes => {
  #    'allow'               => '127\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+', #allow localhost and local network
  #  },
  #  require               => Tomcat::Config::Server::Context['ROOT'],
  #}

  #Create one context for each app being deployed  
  #tomcat::config::server::context { "${web_application_name}":
  #  catalina_base         => $CATALINA_BASE,
  #  parent_engine         => 'Catalina',
  #  parent_host           => 'localhost',
  #  doc_base              => "${web_application_name}",
  #  additional_attributes => {
  #    'path'                => "/${web_application_name}",
  #    'logEffectiveWebXml'  => 'true',
  #  },
  #  require               => Tomcat::Config::Server::Host['localhost'],
  #}
  
  #create remote address valve in application context
  #tomcat::config::server::valve { "${web_application_name}RemoteAddrValve":
  #  catalina_base         => $CATALINA_BASE,
  #  class_name            => 'org.apache.catalina.valves.RemoteAddrValve',
  #  parent_host           => 'localhost',
  #  parent_context        => "${web_application_name}",
  #  additional_attributes => {
  #    'allow'               => '127\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+', #allow localhost and local network
  #  },
  #  require               => Tomcat::Config::Server::Context["${web_application_name}"],
  #}
  
  #create memory listener
  tomcat::config::server::listener { 'MemoryListener':
    catalina_base         => $CATALINA_BASE,
    class_name            => 'org.apache.catalina.core.JreMemoryLeakPreventionListener',
    require               => Tomcat::Install[$CATALINA_HOME],
  }
  
  # create security listener
  tomcat::config::server::listener { 'SecurityListener':
    catalina_base         => $CATALINA_BASE,
    class_name            => 'org.apache.catalina.security.SecurityListener',
    require               => Tomcat::Install[$CATALINA_HOME],
  }

  #create directories for ServerInfo.properties
  file { [ "${CATALINA_HOME}/lib/org", "${CATALINA_HOME}/lib/org/apache", 
           "${CATALINA_HOME}/lib/org/apache/catalina", 
           "${CATALINA_HOME}/lib/org/apache/catalina/util" ]:
    ensure                => 'directory',
    require               => Tomcat::Install[$CATALINA_HOME],
  }

  #place ServerInfo.properties in directory
  file { "${CATALINA_HOME}/lib/org/apache/catalina/util/ServerInfo.properties":
    ensure                => present,
    owner                 => 'tomcat',
    group                 => 'tomcat',
    mode                  => '0750',
    source                => 'puppet:///modules/appliance_components/ServerInfo.properties',
    require               => Tomcat::Install[$CATALINA_HOME],
  }
  
  #create webapps directory in web_parent_dir
  file { [ "${web_parent_dir}/${web_app_dir}", 
           "${web_parent_dir}/${web_app_dir}/ROOT" ]:
    ensure                => 'directory',
    owner                 => 'tomcat',
    group                 => 'tomcat',
    mode                  => '0750',
    require               => Tomcat::Install[$CATALINA_HOME],
  }
  
  exec { 'create_keystore':
    command               => "openssl pkcs12 -export -in /etc/ssl/certs/ssl-cert-snakeoil.pem -inkey /etc/ssl/private/ssl-cert-snakeoil.key -out ${keystore_file} -name tomcat -password pass:${keystore_pass} ",
    path                  => ['/bin', '/usr/bin', '/usr/sbin'],
    require               => Tomcat::Install[$CATALINA_HOME],
  }
  
  #copy tomcat default webapps to web_parent_dir once
  exec { 'copy_to_temp_dir':
    command               => "cp -Lr ${CATALINA_BASE}/webapps /tmp",
    path                  => ['/bin', '/usr/bin', '/usr/sbin'],
    require               => Tomcat::Install[$CATALINA_HOME],
  }
  
  exec { 'clean_old_web_parent_dir':
    command               => "rm -rf ${CATALINA_BASE}/webapps/",
    path                  => ['/bin', '/usr/bin', '/usr/sbin'],
    require               => Exec['copy_to_temp_dir'],
  }
  
  #copy tomcat default webapps to web_parent_dir once
  exec { 'copy_to_web_parent_dir':
    command               => "cp -Lr --remove-destination /tmp/webapps/. ${web_parent_dir}/${web_app_dir}",
    path                  => ['/bin', '/usr/bin', '/usr/sbin'],
    require               => Exec['clean_old_web_parent_dir'],
  }
  
  #copy tomcat default webapps to web_parent_dir once
  exec { 'clean_temp_directory':
    command               => "rm -rf /tmp/webapps/",
    path                  => ['/bin', '/usr/bin', '/usr/sbin'],
    require               => Exec['copy_to_web_parent_dir'],
  }

  #copy default index.jsp to ROOT application
  file { "${web_parent_dir}/${web_app_dir}/ROOT/index.jsp":
    ensure                => present,
    owner                 => 'tomcat',
    group                 => 'tomcat',
    mode                  => '0750',
    source                => 'puppet:///modules/appliance_components/index.jsp',
    require               => Exec['copy_to_web_parent_dir'],
  }

  #create symlink to web_parent_dir in tomcat
  file { "${CATALINA_BASE}/webapps":
    ensure                => 'link',
    owner                 => 'tomcat',
    force                 => true,
    target                => "${web_parent_dir}/${web_app_dir}",
    require               => Exec['copy_to_web_parent_dir'],
  }
  
  file { "${CATALINA_BASE}/installInfo":
    ensure                => present,
    owner                 => 'tomcat',
    group                 => 'tomcat',
    mode                  => '0750',
    source                => 'puppet:///modules/appliance_components/tomcatInstallInfo',
    require               => Tomcat::Install[$CATALINA_HOME],
  }
  
  file { "/etc/systemd/system/tomcat.service":
    ensure                => present,
    owner                 => 'root',
    group                 => 'root',
    mode                  => '0644',
    source                => 'puppet:///modules/appliance_components/tomcat.service',
    require               => Tomcat::Install[$CATALINA_HOME],
  }
    
}