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

describe file("#{conf_dir}/config.json") do
  it { should be_file }
  it { should be_owned_by('consul') }
  it { should be_grouped_into 'consul' }
  its('mode') { should cmp '0640' }
  its('content') { should include('"data_dir": "/var/lib/consul"') }
  its('content') { should include('"bootstrap_expect": 1') }
  its('content') { should include("\"ca_file\": \"#{conf_dir}/ca.crt\"") }
  its('content') { should include("\"cert_file\": \"#{conf_dir}/consul.crt\"") }
  its('content') { should include("\"key_file\": \"#{conf_dir}/consul.key\"") }
end

describe service('consul') do
  it { should be_enabled }
  it { should be_running }
end

[8300, 8501, 8600].each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

tls_info_command = <<EOS
CONSUL_HTTP_SSL=true \
CONSUL_CACERT=#{conf_dir}/ca.crt \
CONSUL_CLIENT_CERT=#{conf_dir}/consul.crt \
CONSUL_CLIENT_KEY=#{conf_dir}/consul.key \
CONSUL_HTTP_ADDR=127.0.0.1:8501 \
CONSUL_TLS_SERVER_NAME=server.dc1.consul \
/usr/local/bin/consul info
EOS

describe command(tls_info_command) do
  its('exit_status') { should eq 0 }
end

describe command('consul info') do
  its('exit_status') { should_not eq 0 }
end
