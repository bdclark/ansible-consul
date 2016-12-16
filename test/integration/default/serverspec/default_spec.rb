require 'spec_helper'

%w(/etc/consul /etc/consul/conf.d /var/lib/consul).each do |dir|
  describe file(dir) do
    it { should be_directory }
    it { should be_owned_by('consul') }
  end
end

describe file('/etc/consul/consul.json') do
  it { should be_file }
  it { should be_owned_by('consul') }
  its(:content) { should contain('"data_dir": "/var/lib/consul"') }
  its(:content) { should contain('"datacenter": "dev"') }
  its(:content) { should contain('"bootstrap_expect": 1') }
  its(:content) { should contain('"ui": true') }
  its(:content) { should contain('"acl_token": "secret_agent"') }
end

describe service('consul') do
  it { should be_enabled }
  it { should be_running }
end

[8300, 8400, 8500, 8600].each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe command('curl -s http://localhost:8500/ui/') do
  its(:stdout) { should match('<title>Consul by HashiCorp</title>') }
end

%w(service-foo service-bar services).each do |fname|
  describe file("/etc/consul/conf.d/#{fname}.json") do
    it { should be_file }
    it { should be_owned_by('consul') }
    it { should be_mode '640' }
  end
end

describe command('curl -s http://localhost:8500/v1/agent/checks') do
  its(:stdout) { should match(/"ssh":{.*"Name":"ssh".*}$/) }
end

describe command('curl -s http://localhost:8500/v1/catalog/service/foo') do
  its(:stdout) { should contain('"ServiceAddress":"1.1.1.1"') }
  its(:stdout) { should contain('"ServicePort":1111') }
end

describe command('curl -s http://localhost:8500/v1/catalog/service/bar') do
  its(:stdout) { should contain('"ServiceAddress":"2.2.2.2"') }
  its(:stdout) { should contain('"ServicePort":2222') }
end

describe command('curl -s http://localhost:8500/v1/catalog/service/bulk-foo') do
  its(:stdout) { should contain('"ServiceAddress":"3.3.3.3"') }
  its(:stdout) { should contain('"ServicePort":3333') }
end

describe command('curl -s http://localhost:8500/v1/catalog/service/bulk-bar') do
  its(:stdout) { should contain('"ServiceAddress":"4.4.4.4"') }
  its(:stdout) { should contain('"ServicePort":4444') }
end

dns_server = '127.0.0.1' if os[:family] == 'redhat' && os[:release].to_i == 6

describe command("host foo.service.consul #{dns_server}") do
  its(:stdout) { should match(/^foo.service.consul has address 1.1.1.1/) }
end

describe command("host -t SRV foo.service.consul #{dns_server}") do
  its(:stdout) { should match(/^foo.service.consul has SRV record 1 1 1111/) }
end

describe port(53) do
  it { should be_listening.with(:udp) }
  it { should be_listening.with(:tcp) }
end

describe command('consulate kv ls') do
  its(:exit_status) { should eq 0 }
end