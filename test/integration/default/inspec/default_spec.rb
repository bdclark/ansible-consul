
conf_dir = "/etc/consul.d"

describe file(conf_dir) do
  it { should be_directory }
  it { should be_owned_by('root') }
  it { should be_grouped_into 'consul' }
  its('mode') { should cmp '0750' }
end

describe file('/var/lib/consul') do
  it { should be_directory }
  it { should be_owned_by('consul') }
  it { should be_grouped_into 'consul' }
  its('mode') { should cmp '0750' }
end

describe json("#{conf_dir}/config.json") do
  its(['data_dir']) { should eq ('/var/lib/consul') }
  its(['datacenter']) { should eq ('dev') }
  its(['bootstrap_expect']) { should eq (1) }
  its(['ui']) { should eq (true) }
  its(['acl_token']) { should eq ('secret_agent') }
end

describe file("#{conf_dir}/config.json") do
  it { should be_file }
  it { should be_owned_by('consul') }
  it { should be_grouped_into 'consul' }
  its('mode') { should cmp '0640' }
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
  describe file("#{conf_dir}/#{fname}.json") do
    it { should be_file }
    it { should be_owned_by('consul') }
    its('mode') { should cmp '0640' }
  end
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

describe command("dig foo.service.consul @127.0.0.1 -p 8600") do
  its('stdout') { should match(/^foo.service.consul.\s0	IN\sA\s1.1.1.1/) }
end

describe command("dig -t SRV foo.service.consul @127.0.0.1 -p 8600") do
  its('stdout') { should match(/^foo.service.consul.\s0\sIN\sSRV\s1\s1\s1111/) }
end
