
%w(/etc/consul /etc/consul/conf.d).each do |dir|
  describe file(dir) do
    it { should be_directory }
    it { should be_owned_by('root') }
    it { should be_grouped_into 'consul' }
    its('mode') { should cmp '0750' }
  end
end

describe file('/var/lib/consul') do
  it { should be_directory }
  it { should be_owned_by('consul') }
  it { should be_grouped_into 'consul' }
  its('mode') { should cmp '0750' }
end

describe file('/etc/consul/config.json') do
  it { should be_file }
  it { should be_owned_by('consul') }
  it { should be_grouped_into 'consul' }
  its('mode') { should cmp '0640' }
  its('content') { should include('"data_dir": "/var/lib/consul"') }
  its('content') { should include('"datacenter": "dev"') }
  its('content') { should include('"bootstrap_expect": 1') }
  its('content') { should include('"ui": true') }
  its('content') { should include('"acl_token": "secret_agent"') }
  its('content') { should_not include('ca_file') }
  its('content') { should_not include('cert_file') }
  its('content') { should_not include('key_file') }
end

describe service('consul') do
  it { should be_enabled }
  it { should be_running }
end

[8300, 8500, 8600].each do |p|
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
    its('mode') { should cmp '0640' }
  end
end

describe file('/usr/local/bin/configure-consul') do
  it { should be_file }
  it { should be_owned_by('root') }
  its('mode') { should cmp '0755' }
end

describe command('configure-consul --dry-run --client 0.0.0.0 --server --retry-join "provider=aws"') do
  its('stdout') { should match(%r{"data_dir": "/var/lib/consul"}) }
  its('stdout') { should match(%r{"client_addr": "0.0.0.0"}) }
  its('stdout') { should match(%r{"server": true}) }
  its('stdout') { should match(%r{"retry_join": \[\n\s*"provider=aws"\n\s*\]}) }
end

describe command('curl -s http://localhost:8500/v1/agent/checks') do
  its('stdout') { should match(/"ssh":{.*"Name":"ssh".*}$/) }
end

describe command('curl -s http://localhost:8500/v1/catalog/service/foo') do
  its('stdout') { should include('"ServiceAddress":"1.1.1.1"') }
  its('stdout') { should include('"ServicePort":1111') }
end

describe command('curl -s http://localhost:8500/v1/catalog/service/bar') do
  its('stdout') { should include('"ServiceAddress":"2.2.2.2"') }
  its('stdout') { should include('"ServicePort":2222') }
end

describe command('curl -s http://localhost:8500/v1/catalog/service/bulk-foo') do
  its('stdout') { should include('"ServiceAddress":"3.3.3.3"') }
  its('stdout') { should include('"ServicePort":3333') }
end

describe command('curl -s http://localhost:8500/v1/catalog/service/bulk-bar') do
  its('stdout') { should include('"ServiceAddress":"4.4.4.4"') }
  its('stdout') { should include('"ServicePort":4444') }
end

dns_server = '127.0.0.1' if os[:family] == 'redhat' && os[:release].to_i == 6

describe command("host foo.service.consul #{dns_server}") do
  its('stdout') { should match(/^foo.service.consul has address 1.1.1.1/) }
end

describe command("host -t SRV foo.service.consul #{dns_server}") do
  its('stdout') { should match(/^foo.service.consul has SRV record 1 1 1111/) }
end

describe port(53) do
  it { should be_listening }
end
