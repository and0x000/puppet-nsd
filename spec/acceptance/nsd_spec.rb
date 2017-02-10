require 'spec_helper_acceptance'

describe 'nsd class' do
  context 'defaults' do
    it 'work with no errors' do
      pp = 'class {\'::nsd\': }'
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_failures: true).exit_code).to eq 0
    end
    describe service('nsd') do
      it { is_expected.to be_running }
    end
    describe port(53) do
      it { is_expected.to be_listening }
    end
    describe command('nsd-checkconf /etc/nsd/nsd.conf || cat /etc/nsd/nsd.conf'), if: os[:family] == 'ubuntu' do
      its(:stdout) { is_expected.to match %r{} }
    end
    describe command('nsd-checkconf /usr/local/etc/nsd/nsd.conf || cat /usr/local/etc/nsd/nsd.conf'), if: os[:family] == 'freebsd' do
      its(:stdout) { is_expected.to match %r{} }
    end
  end
  context 'root' do
    it 'work with no errors' do
      pp = <<-EOS
  class {'::nsd':
      remotes => {
        'lax.xfr.dns.icann.org' => {
          'address4' => '192.0.32.132'
        },
        'iad.xfr.dns.icann.org' => {
          'address4' => '192.0.47.132'
        },
      },
      rrl_whitelist => ['nxdomain', 'referral']
  }
  nsd::zone {
    '.':
      masters  => ['lax.xfr.dns.icann.org', 'iad.xfr.dns.icann.org'],
      zonefile => 'root';
    'arpa.':
      masters  => ['lax.xfr.dns.icann.org', 'iad.xfr.dns.icann.org'];
    'root-servers.net.':
      masters  => ['lax.xfr.dns.icann.org', 'iad.xfr.dns.icann.org'];
  }
      EOS
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_failures: true).exit_code).to eq 0
      # sleep to allow zone transfer (value probably to high)
      sleep(10)
    end
    describe service('nsd') do
      it { is_expected.to be_running }
    end
    describe port(53) do
      it { is_expected.to be_listening }
    end
    describe command('nsd-checkconf /etc/nsd/nsd.conf || cat /etc/nsd/nsd.conf'), if: os[:family] == 'ubuntu' do
      its(:stdout) { is_expected.to match %r{} }
    end
    describe command('nsd-checkconf /usr/local/etc/nsd/nsd.conf || cat /usr/local/etc/nsd/nsd.conf'), if: os[:family] == 'freebsd' do
      its(:stdout) { is_expected.to match %r{} }
    end
    describe command('dig +short soa . @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
    end
    describe command('dig +short soa arpa. @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
    end
    describe command('dig +short soa root-servers.net. @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{a.root-servers.net. nstld.verisign-grs.com.} }
    end
  end
  context 'as112' do
    it 'work with no errors' do
      pp = 'class {\'::nsd::as112\': }'
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_failures: true).exit_code).to eq 0
    end
    describe service('nsd') do
      it { is_expected.to be_running }
    end
    describe port(53) do
      it { is_expected.to be_listening }
    end
    describe command('nsd-checkconf /etc/nsd/nsd.conf || cat /etc/nsd/nsd.conf'), if: os[:family] == 'ubuntu' do
      its(:stdout) { is_expected.to match %r{} }
    end
    describe command('nsd-checkconf /usr/local/etc/nsd/nsd.conf || cat /usr/local/etc/nsd/nsd.conf'), if: os[:family] == 'freebsd' do
      its(:stdout) { is_expected.to match %r{} }
    end
    describe command('dig +short soa empty.as112.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{blackhole.as112.arpa. noc.dns.icann.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 10.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 16.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 17.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 18.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 19.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 20.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 21.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 22.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 23.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 24.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 25.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 26.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 27.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 28.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 29.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 30.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 31.172.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 168.192.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
    describe command('dig +short soa 254.169.in-addr.arpa @127.0.0.1') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{prisoner.iana.org. hostmaster.root-servers.org. 1 604800 60 604800 604800} }
    end
  end
end
