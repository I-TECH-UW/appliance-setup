import os
import subprocess
import shutil
import time

#This script configs tomcat in additional ways that are
#missed by puppet's tomcat config

CATALINA_HOME='/usr/share/tomcat8.5'

def config():
    print('Configuring tomcat...')
    remove_tomcat_extra_apps()
    configure_web_xml()
    configure_catalina_properties()
    restrict_tomcat_files()
    enable_tomcat_service()
    print("Done configuring tomcat")

def remove_tomcat_extra_apps():
    docs = os.path.join(CATALINA_HOME, 'webapps/docs')
    examples = os.path.join(CATALINA_HOME, 'webapps/examples')
    host_manager = os.path.join(CATALINA_HOME, 'webapps/host-manager')
    manager = os.path.join(CATALINA_HOME, 'webapps/manager')
    managerXml = os.path.join(CATALINA_HOME, 'conf/Catalina/localhost/manager.xml')
    print('Deleting unneccessary tomcat files...')
    if os.path.exists(docs):
        shutil.rmtree(docs)
    if os.path.exists(examples):
        shutil.rmtree(examples)
    if os.path.exists(host_manager):
        shutil.rmtree(host_manager)
    if os.path.exists(manager):
        shutil.rmtree(manager)
    if os.path.exists(managerXml):
        shutil.rmtree(managerXml)

def configure_web_xml():
    from lxml import etree
    print('Configuring tomcat web.xml...')
          
    '''
  <security-constraint>
    <web-resource-collection>
      <web-resource-name>HTTPS ONLY</web-resource-name>
      <url-pattern>/*</url-pattern>
    </web-resource-collection>
    <user-data-constraint>
      <transport-guarantee>CONFIDENTIAL</transport-guarantee>
    </user-data-constraint>
  </security-constraint>
  <error-page>
    <exception-type>java.lang.Throwable</exception-type>
    <location>/error.jsp</location>
  </error-page>
    '''
    parser = etree.XMLParser(remove_blank_text=True)
    elem_tree = etree.parse(os.path.join(CATALINA_HOME, 'conf/web.xml'), parser)
    
    for element in elem_tree.xpath("//*[local-name() = 'security-constraint']"):
        element.getparent().remove(element)
    for element in elem_tree.xpath("//*[local-name() = 'error-page']"):
        element.getparent().remove(element)

    #setting security constraint to https only in web.xml
    sec_con = etree.SubElement(elem_tree.getroot(), 'security-constraint')
    wrc = etree.SubElement(sec_con, 'web-resource-collection')
    etree.SubElement(wrc, 'web-resource-name').text = 'HTTPS ONLY'
    etree.SubElement(wrc, 'url-pattern').text = '/*'
    udc = etree.SubElement(sec_con, 'user-data-constraint')
    etree.SubElement(udc, 'transport-guarantee').text = 'CONFIDENTIAL'
    
    #setting to custom error-page to control stack trace
    err_page = etree.SubElement(elem_tree.getroot(), 'error-page')
    etree.SubElement(err_page, 'exception-type').text = 'java.lang.Throwable'
    etree.SubElement(err_page, 'location').text = '/error.jsp'
    
    elem_tree.write(os.path.join(CATALINA_HOME, 'conf/web.xml'), pretty_print=True)
    
def configure_catalina_properties():
    print('Configuring tomcat catalina.properties...')
    filename = os.path.join(CATALINA_HOME, 'conf/catalina.properties')
    f = open(filename, "a+")
    if not in_file('org.apache.catalina.STRICT_SERVLET_COMPLIANCE=true', filename):
        f.write('\norg.apache.catalina.STRICT_SERVLET_COMPLIANCE=true')
    if not in_file('org.apache.catalina.connector.RECYCLE_FACADES=true', filename):
        f.write('\norg.apache.catalina.connector.RECYCLE_FACADES=true')
    if not in_file('org.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=false', filename):
        f.write('\norg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=false')
    if not in_file('org.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=false', filename):
        f.write('\norg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=false')
    if not in_file('org.apache.coyote.USE_CUSTOM_STATUS_MSG_IN_HEADER=false', filename):
        f.write('\norg.apache.coyote.USE_CUSTOM_STATUS_MSG_IN_HEADER=false\n')
       
def restrict_tomcat_files():
    print('Restricting tomcat file permissions...')
    cmd= "chown -RL tomcat:tomcat " + CATALINA_HOME
    protect_files = subprocess.Popen(cmd.split(),
                              stdout=None,
                              stderr=None)
    status = protect_files.wait()
    
    cmd= "chmod -R g-w,o-rwx " + CATALINA_HOME
    protect_files = subprocess.Popen(cmd.split(),
                              stdout=None,
                              stderr=None)
    status = protect_files.wait() 

def enable_tomcat_service():
    print('Enabling Tomcat as a service...')
    cmd= "sudo systemctl daemon-reload"
    reload_daemons = subprocess.Popen(cmd.split(),
                              stdout=None,
                              stderr=None)
    status = reload_daemons.wait()   
    
    cmd= "sudo systemctl start tomcat.service"
    start_tomcat = subprocess.Popen(cmd.split(),
                              stdout=None,
                              stderr=None)
    status = start_tomcat.wait()
    
    cmd= "sudo systemctl enable tomcat.service"
    enablet_tomcat = subprocess.Popen(cmd.split(),
                              stdout=None,
                              stderr=None)
    status = enablet_tomcat.wait()
    
def in_file(search_string, filename):
    f = open(filename)
    for line in f:
        if search_string in line:
            f.close()
            return True
    return False
  