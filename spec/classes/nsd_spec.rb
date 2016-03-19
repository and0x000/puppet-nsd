require 'spec_helper'
describe 'nsd', :type => :class do

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      case facts[:operatingsystem]
      when 'Ubuntu'
        case facts['lsbdistcodename']
        when 'precise'
          let(:nsd_package_name) { 'nsd3' }
          let(:nsd_service_name) { 'nsd3' }
          let(:nsd_conf_dir)     { '/etc/nsd3' }
          let(:zonesdir)         { '/var/lib/nsd3' }
          let(:nsd_conf_file)    { "#{nsd_conf_dir}/nsd.conf" }
          let(:database)         { "#{zonesdir}/nsd.db" }
          let(:xfrdfile)         { "#{zonesdir}/xfrd.state" }
          let(:init)             { 'base' }
          let(:pidfile)          { '/run/nsd3/nsd.pid' }
          let(:logrotate_enable) { true }
        else
          let(:nsd_package_name) { 'nsd' }
          let(:nsd_service_name) { 'nsd' }
          let(:nsd_conf_dir)     { '/etc/nsd' }
          let(:zonesdir)         { '/var/lib/nsd' }
          let(:nsd_conf_file)    { "#{nsd_conf_dir}/nsd.conf" }
          let(:database)         { "#{zonesdir}/nsd.db" }
          let(:xfrdfile)         { "#{zonesdir}/xfrd.state" }
          let(:init)             { 'upstart' }
          let(:pidfile)          { '/run/nsd/nsd.pid' }
          let(:logrotate_enable) { true }
        end
      else
        let(:nsd_package_name) { 'nsd' }
        let(:nsd_service_name) { 'nsd' }
        let(:nsd_conf_dir)     { '/usr/local/etc/nsd' }
        let(:zonesdir)         { "#{nsd_conf_dir}/data" }
        let(:nsd_conf_file)    { "#{nsd_conf_dir}/nsd.conf" }
        let(:database)         { "/var/db/nsd/nsd.db" }
        let(:xfrdfile)         { "/var/db/nsd/xfrd.state" }
        let(:init)             { 'freebsd' }
        let(:pidfile)          { '/var/run/nsd/nsd.pid' }
        let(:logrotate_enable) { true }
      end
      let(:zone_subdir) { "#{zonesdir}/zone" }
      describe 'check default config' do

        it { is_expected.to compile }
        it { is_expected.to contain_package(nsd_package_name).with_ensure(
          'present') }
        it { is_expected.to contain_concat(nsd_conf_file) }
        it { 
          is_expected.to contain_concat_fragment('nsd_server').with(
            :target => nsd_conf_file
          ).with_content(
            /ip-transparent: no/
          ).with_content(
            /debug-mode: no/
          ).with_content(
            /database: #{database}/
          ).with_content(
            /identity: foo.example.com/
          ).with_content(
            /nsid: "666f6f2e6578616d706c652e636f6d"/
          ).without_content(
            /logfile:/
          ).with_content(
            /server-count: 1/
          ).with_content(
            /tcp-count: 250/
          ).with_content(
            /tcp-query-count: 0/ 
          ).without_content(
            /tcp-timeout:/
          ).with_content(
            /ipv4-edns-size: 4096/
          ).with_content(
            /ipv6-edns-size: 4096/
          ).with_content(
            /pidfile: #{pidfile}/
          ).with_content(
            /port: 53/
          ).without_content(
            /statistics:/
          ).without_content(
            /chroot:/
          ).with_content(
            /username: nsd/
          ).with_content(
            /zonesdir: #{zonesdir}/
          ).without_content(
            /difffile:/
          ).with_content(
            /xfrdfile: #{xfrdfile}/
          ).with_content(
            /xfrd-reload-timeout: 1/
          ).with_content(
            /verbosity: 0/
          ).with_content(
            /hide-version: no/
          ).with_content(
            /rrl-size: 1000000/
          ).with_content(
            /rrl-ratelimit: 200/
          ).with_content(
            /rrl-slip: 2/
          ).with_content(
            /rrl-ipv4-prefix-length: 24/
          ).with_content(
            /rrl-ipv6-prefix-length: 64/
          ).with_content(
            /rrl-whitelist-ratelimit: 4000/
          ).without_content(
            /control-enable:/
          )
        }
        it { is_expected.to contain_file(zonesdir).with(
          :ensure => 'directory',
          :owner  => 'nsd',
          :group  => 'nsd',
        ) }
        it { is_expected.to contain_file(zone_subdir).with(
          :ensure => 'directory',
          :owner  => 'nsd',
          :group  => 'nsd',
        ) }
        it { is_expected.to contain_file(nsd_conf_dir).with(
          :ensure => 'directory',
          :mode   => '0755',
          :group  => 'nsd',
        ) }
        it { is_expected.to contain_service(nsd_service_name).with(
          :ensure   => true,
          :enable   => true,
        ) }
      end

      describe 'check changin default parameters' do
        context 'enable' do
          let(:params) {{ :enable => false }}
          it { is_expected.to contain_service(
            nsd_service_name).with(
              :ensure   => false,
              :enable   => false,
        ) }
        end
        context 'tsig' do
          let(:params) {{ :tsig => {
            'name' => 'foo',
            'data' => 'aaaa',
            }
          }}
          it { is_expected.to contain_nsd__tsig('foo').with(
            :data => 'aaaa'
          )}
        end
        context 'zones' do
          let(:params) {{ 
            :zones => {
              'test' => { 
                'masters'          => ['192.0.2.1'],
                'notify_addresses' => ['192.0.2.1'],
                'allow_notify'     => ['192.0.2.1'],
                'provide_xfr'      => ['192.0.2.1'],
                'zones'            => ['example.com'],
              }
            }
          }}
          it { is_expected.to contain_nsd__zone('test').with(
            :masters          => ['192.0.2.1'],
            :notify_addresses => ['192.0.2.1'],
            :allow_notify     => ['192.0.2.1'],
            :provide_xfr      => ['192.0.2.1'],
            :zones            => ['example.com'],
          )}
        end
        context 'files' do
          let(:params) {{ 
            :files => { 
              'foo' => {
                'source' => 'puppet:///foo.zone',
              },
              'bar' => {
                'content' => 'foo.zone',
              }
            }
          }}
          it { is_expected.to contain_nsd__file('foo').with(
            :source => 'puppet:///foo.zone'
          ) }
          it { is_expected.to contain_nsd__file('bar').with(
            :content => 'foo.zone'
          ) }
        end
        context 'tsigs' do
          let(:params) {{ 
            :tsigs => { 
              'foo' => { 
                'data' => 'aaaa'
              }
            }
          }}
          it { is_expected.to contain_nsd__tsig('foo').with(
            :data => 'aaaa'
          ) }
        end
        context 'ip_addresses' do
          let(:params) {{ :ip_addresses => ['192.0.2.1'] }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /ip-address: 192.0.2.1/
          ) }
        end
        context 'ip_transparent' do
          let(:params) {{ :ip_transparent => true }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /ip-transparent: yes/
          ) }
        end
        context 'debug_mode' do
          let(:params) {{ :debug_mode => true }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /debug-mode: yes/
          ) }
        end
        context 'identity' do
          let(:params) {{ :identity => 'foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /identity: foo/
          ) }
        end
        context 'nsid' do
          let(:params) {{ :nsid => 'foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /nsid: "666f6f"/
          ) }
        end
        context 'logfile' do
          let(:params) {{ :logfile => '/foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /logfile: \/foo/
          ) }
        end
        context 'server_count' do
          let(:params) {{ :server_count => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /server-count: 6/
          ) }
        end
        context 'tcp_count' do
          let(:params) {{ :tcp_count => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /tcp-count: 6/
          ) }
        end
        context 'tcp_query_count' do
          let(:params) {{ :tcp_query_count => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /tcp-query-count: 6/
          ) }
        end
        context 'tcp_timeout' do
          let(:params) {{ :tcp_timeout => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /tcp-timeout: 6/
          ) }
        end
        context 'ipv4_edns_size' do
          let(:params) {{ :ipv4_edns_size => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /ipv4-edns-size: 6/
          ) }
        end
        context 'ipv6_edns_size' do
          let(:params) {{ :ipv6_edns_size => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /ipv6-edns-size: 6/
          ) }
        end
        context 'pidfile' do
          let(:params) {{ :pidfile => '/foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /pidfile: \/foo/
          ) }
        end
        context 'port' do
          let(:params) {{ :port => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /port: 6/
          ) }
        end
        context 'statistics' do
          let(:params) {{ :statistics => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /statistics: 6/
          ) }
        end
        context 'chroot' do
          let(:params) {{ :chroot => '/foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /chroot: \/foo/
          ) }
        end
        context 'username' do
          let(:params) {{ :username => 'foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /username: foo/
          ) }
        end
        context 'zonesdir' do
          let(:params) {{ :zonesdir => '/foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /zonesdir: \/foo/
          ) }
        end
        context 'difffile' do
          let(:params) {{ :difffile => '/foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /difffile: \/foo/
          ) }
        end
        context 'xfrdfile' do
          let(:params) {{ :xfrdfile => '/foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /xfrdfile: \/foo/
          ) }
        end
        context 'xfrd_reload_timeout' do
          let(:params) {{ :xfrd_reload_timeout => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /xfrd-reload-timeout: 6/
          ) }
        end
        context 'verbosity' do
          let(:params) {{ :verbosity => 1 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /verbosity: 1/
          ) }
        end
        context 'hide_version' do
          let(:params) {{ :hide_version => true }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /hide-version: yes/
          ) }
        end
        context 'rrl_size' do
          let(:params) {{ :rrl_size => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /rrl-size: 6/
          ) }
        end
        context 'rrl_ratelimit' do
          let(:params) {{ :rrl_ratelimit => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /rrl-ratelimit: 6/
          ) }
        end
        context 'rrl_slip' do
          let(:params) {{ :rrl_slip => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /rrl-slip: 6/
          ) }
        end
        context 'rrl_ipv4_prefix_length' do
          let(:params) {{ :rrl_ipv4_prefix_length => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /rrl-ipv4-prefix-length: 6/
          ) }
        end
        context 'rrl_ipv6_prefix_length' do
          let(:params) {{ :rrl_ipv6_prefix_length => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /rrl-ipv6-prefix-length: 6/
          ) }
        end
        context 'rrl_whitelist_ratelimit' do
          let(:params) {{ :rrl_whitelist_ratelimit => 6 }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /rrl-whitelist-ratelimit: 6/
          ) }
        end
        context 'control_enable' do
          let(:params) {{ :control_enable => true }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /control-enable: yes/
          ) }
        end
        context 'database' do
          let(:params) {{ :database => '/foo' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_content(
            /database: \/foo/
          ) }
        end
        context 'nsd_package_name' do
          let(:params) {{ :nsd_package_name => 'foo' }}
          it { is_expected.to contain_package('foo').with_ensure('present')}
        end
        context 'nsd_service_name' do
          let(:params) {{ :nsd_service_name => 'foo' }}
          it { is_expected.to contain_service('foo') }
        end
        context 'nsd_conf_file' do
          let(:params) {{ :nsd_conf_file => '/foo.cfg' }}
          it { is_expected.to contain_concat_fragment('nsd_server').with_target('/foo.cfg') }
        end
      end
 
      describe 'check bad parameters' do
        context 'enable' do
          let(:params) {{ :enable => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsig' do
          let(:params) {{ :tsig => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'slave_addresses' do
          let(:params) {{ :slave_addresses => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zones' do
          let(:params) {{ :zones => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'files' do
          let(:params) {{ :files => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsigs' do
          let(:params) {{ :tsigs => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logrotate_enable' do
          let(:params) {{ :logrotate_enable => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logrotate_rotate' do
          let(:params) {{ :logrotate_rotate => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logrotate_size' do
          let(:params) {{ :logrotate_size => true }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'instance' do
          let(:params) {{ :instance => true }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'master' do
          let(:params) {{ :master => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'server_template' do
          let(:params) {{ :server_template => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zones_template' do
          let(:params) {{ :tsig => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ip_addresses' do
          let(:params) {{ :ip_addresses => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'debug_mode' do
          let(:params) {{ :debug_mode => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'identity' do
          let(:params) {{ :identity => true }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'nsid' do
          let(:params) {{ :nsid => true }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logfile' do
          let(:params) {{ :logfile => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'server_count' do
          let(:params) {{ :server_count => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tcp_count' do
          let(:params) {{ :tcp_count => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tcp_query_count' do
          let(:params) {{ :tcp_query_count => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tcp_timeout' do
          let(:params) {{ :tcp_timeout => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ipv4_edns_size' do
          let(:params) {{ :ipv4_edns_size => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ipv6_edns_size' do
          let(:params) {{ :ipv6_edns_size => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'pidfile' do
          let(:params) {{ :pidfile => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'port' do
          let(:params) {{ :port => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'port to big' do
          let(:params) {{ :port => 9999999 }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'statistics' do
          let(:params) {{ :statistics => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'chroot' do
          let(:params) {{ :chroot => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'username' do
          let(:params) {{ :username => true }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zonesdir' do
          let(:params) {{ :zonesdir => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'difffile' do
          let(:params) {{ :difffile => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'xfrdfile' do
          let(:params) {{ :xfrdfile => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'xfrd_reload_timeout' do
          let(:params) {{ :xfrd_reload_timeout => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'verbosity' do
          let(:params) {{ :verbosity => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'verbosity to big' do
          let(:params) {{ :verbosity => 3 }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'hide_version' do
          let(:params) {{ :hide_version => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'rrl_size' do
          let(:params) {{ :rrl_size => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'rrl_ratelimit' do
          let(:params) {{ :rrl_ratelimit => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'rrl_slip' do
          let(:params) {{ :rrl_slip => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'rrl_ipv4_prefix_length' do
          let(:params) {{ :rrl_ipv4_prefix_length => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'rrl_ipv6_prefix_length' do
          let(:params) {{ :rrl_ipv6_prefix_length => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'rrl_whitelist_ratelimit' do
          let(:params) {{ :rrl_whitelist_ratelimit => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'control_enable' do
          let(:params) {{ :control_enable => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'control_interface' do
          let(:params) {{ :control_interface => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'server_key_file' do
          let(:params) {{ :server_key_file => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'server_cert_file' do
          let(:params) {{ :server_cert_file => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'control_key_file' do
          let(:params) {{ :control_key_file => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'control_cert_file' do
          let(:params) {{ :control_cert_file => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'init' do
          let(:params) {{ :init => true }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'database' do
          let(:params) {{ :database => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'nsd_package_name' do
          let(:params) {{ :nsd_package_name => true }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'nsd_service_name' do
          let(:params) {{ :nsd_service_name => true }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'nsd_conf_dir' do
          let(:params) {{ :nsd_conf_dir => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zone_subdir' do
          let(:params) {{ :zone_subdir => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'nsd_conf_file' do
          let(:params) {{ :nsd_conf_file => 'foo' }}
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
