require 'spec_helper'


services = []
yumrepos = ['epel','rpmforge','rpmforge-extras','atrpms']

host = "localhost"

yumrepos.each do |yumrepo|
  describe yumrepo(yumrepo) do
    it { should exist }
  end
end

# TODO - implement recipe first
#
# describe host(alfresco_host) do
#   it { should be_resolvable.by('hosts') }
# end

describe "Running services" do
  services.each do |service|
    it "include #{service}" do
      expect(service(service)).to be_running
    end
  end
end

# TODO - not working
#
# -A INPUT -p tcp --dport 80 -j ACCEPT
# -A INPUT -p tcp --dport 443 -j ACCEPT
# -A INPUT -p tcp --dport 5701 -j ACCEPT
# -A INPUT -p tcp --dport 40000 -j ACCEPT
# -A INPUT -p tcp --dport 40010 -j ACCEPT
# -A INPUT -p tcp --dport 40020 -j ACCEPT
#
# describe iptables do
#   it { should have_rule("-A INPUT -p tcp --dport 80 -j ACCEPT") }
# end

# TODO - not working
#
# describe cron do
#   it { should have_entry '*/30 * * * * root find /var/cache/tomcat-alfresco -mmin +30 -type f -exec rm -rf {} \;' }
#   it { should have_entry '*/30 * * * * root find /var/cache/tomcat-share -mmin +30 -type f -exec rm -rf {} \;' }
#   it { should have_entry '*/30 * * * * root find /var/cache/tomcat-solr -mmin +30 -type f -exec rm -rf {} \;' }
# end
