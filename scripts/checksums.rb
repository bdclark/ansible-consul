#!/usr/bin/env ruby

require 'open-uri'
require 'yaml'

versions = %w(0.5.0 0.5.1 0.5.2 0.6.0 0.6.1 0.6.2 0.6.3 0.6.4)
keepers = %w(linux_amd64)
results = { 'consul_checksums' => {} }

class Array
  def partial_include? search
    self.each do |e|
      return true if search.include?(e.to_s)
    end
    return false
  end
end

versions.each do |v|
  url = "https://releases.hashicorp.com/consul/#{v}/consul_#{v}_SHA256SUMS"
  open(url) do |u|
    content = u.read
    content.each_line do |line|
      checksum, fname = line.gsub(/\s+/, ' ').strip.split(' ')
      next unless keepers.partial_include?(fname)
      # puts "#{fname}: sha256:#{checksum}"
      results['consul_checksums'][fname] = "sha256:#{checksum}"
    end
  end
end

# checksums_path = File.expand_path('../../defaults/checkums.yml', __FILE__)
# File.open(checksums_path, 'w') {|f| f.write results.to_yaml }

puts results.to_yaml
