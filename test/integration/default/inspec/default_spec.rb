conf_dir = '/etc/consul.d'

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
  its(['data_dir']) { should eq '/var/lib/consul' }
  its(['datacenter']) { should eq 'dev' }
  its(['bootstrap_expect']) { should eq 1 }
  its(['ui']) { should eq true }
  its(['acl_token']) { should eq 'secret_agent' }
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

%w[service-foo service-bar service-baz services].each do |fname|
  describe file("#{conf_dir}/#{fname}.json") do
    it { should be_file }
    it { should be_owned_by('consul') }
    its('mode') { should cmp '0640' }
  end
end

describe json(command: 'curl -s http://localhost:8500/v1/agent/checks') do
  its(%w[ssh Name]) { should eq 'ssh' }
end

describe json(command: 'curl -s http://localhost:8500/v1/catalog/service/foo') do
  its([0, 'ServiceAddress']) { should eq '1.1.1.1' }
  its([0, 'ServicePort']) { should eq 1111 }
end

describe json(command: 'curl -s http://localhost:8500/v1/catalog/service/bar') do
  its([0, 'ServiceAddress']) { should eq '2.2.2.2' }
  its([0, 'ServicePort']) { should eq 2222 }
end

describe json(command: 'curl -s http://localhost:8500/v1/catalog/service/bulk-foo') do
  its([0, 'ServiceAddress']) { should eq '3.3.3.3' }
  its([0, 'ServicePort']) { should eq 3333 }
end

describe json(command: 'curl -s http://localhost:8500/v1/catalog/service/bulk-bar') do
  its([0, 'ServiceAddress']) { should eq '4.4.4.4' }
  its([0, 'ServicePort']) { should eq 4444 }
end

describe json(command: 'curl -s http://localhost:8500/v1/catalog/service/baz') do
  its([0, 'ServiceAddress']) { should eq '5.5.5.5' }
  its([0, 'ServicePort']) { should eq 5555 }
  its([0, 'ServiceWeights', 'Passing']) { should eq 2 }
  its([0, 'ServiceWeights', 'Warning']) { should eq 1 }
end

describe command('dig foo.service.consul @127.0.0.1 -p 8600') do
  its('stdout') { should match(/^foo.service.consul.\s0	IN\sA\s1.1.1.1/) }
end

describe command('dig -t SRV foo.service.consul @127.0.0.1 -p 8600') do
  its('stdout') { should match(/^foo.service.consul.\s0\sIN\sSRV\s1\s1\s1111/) }
end
