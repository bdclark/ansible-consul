# Ansible Consul Role

Ansible role to install and configure [Consul][1] agent (client and server).

Also optionally installs dnmasq for consul dns domain forwarding, and consulate
python API client.

Role Variables
--------------

See [defaults/main.yml](defaults/main.yml) for a list and description of
variables used in this role.

Example Playbooks/Snippets
----------------

### Basic client/server installation examples

```yaml
- hosts: consul_servers
  become: true
  vars:
    # set consul bind_addr to ip addy of eth1
    consul_auto_bind_iface: eth1
    # install consulate API client
    consul_install_consulate: true
    # any valid agent options
    consul_config:
      server: true
      bootstrap_expect: 3
      ui: true
      leave_on_terminate: false
      retry_join: "{{ groups['consul_servers'] | map('extract', hostvars, ['ansible_eth1', 'ipv4', 'address']) | list }}"
  roles:
    - consul

- hosts: app_servers
  become: true
  vars:
    # install dnsmasq for consul dns domain forwarding
    consul_install_dnsmasq: true
    # agent options
    consul_config:
      leave_on_terminate: true
      retry_join: "{{ groups['consul_servers'] | map('extract', hostvars, ['consul_config', 'bind_addr']) | list }}"
  roles:
    - consul
```

### Consul service/check definitions

Consul service definition json files can be written by setting `consul_services`
(file per service) or `consul_services_bulk` (multiple services in one file).

The following are examples for configuring consul services, but the same approach
works for check definitions as well by setting `consul_checks` and
`consul_checks_bulk`.

```yaml
# writes service-redis.json
# service name defaults to 'redis' since name not specified
consul_services:
  redis:
    port: 6379
    check:
      tcp: localhost:6379
      interval: 30s
      timeout: 1s

# writes service-redis_6000.json and service-redis_7000.json
consul_services:
  redis_6000:
    name: redis
    id: redis6000
    address: 127.0.0.1
    port: 6000
    tags:
      - master
    check:
      script: /bin/check_redis -p 6000
      interval: 10s
      ttl: 30s
  redis_7000:
    name: redis
    id: redis7000
    address: 127.0.0.1
    port: 6000
    tags:
      - delayed
      - slave
    check:
      script: /bin/check_redis -p 7000
      interval: 10s
      ttl: 60s

# same services, but writing all services in services.json instead
consul_services_bulk:
  - name: redis
    id: redis6000
    address: 127.0.0.1
    port: 6000
    tags:
      - master
  - name: redis
    id: redis7000
    address: 127.0.0.1
    port: 6000
    tags:
      - delayed
      - slave
```

License
-------

The MIT License (MIT)
Copyright (c) 2016 Brian Clark <brian@clark.zone>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[1]: https://www.consul.io/
