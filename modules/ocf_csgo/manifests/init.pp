class ocf_csgo {
  include ocf::apt::i386
  include ocf::firewall::allow_desktops

  ocf::firewall::firewall46 {
    '100 allow srcds':
      opts => {
        chain => 'PUPPET-INPUT',
  proto       => ['tcp', 'udp'],
  dport       => 27015,
  action      => 'accept',
      };

    '100 allow SourceTV':
      opts => {
        chain => 'PUPPET-INPUT',
  proto       => 'udp',
  dport       => 27015,
  action      => 'accept',
      };

    '100 allow srcds clientport':
      opts => {
        chain => 'PUPPET-INPUT',
  proto       => 'udp',
  dport       => 27005,
  action      => 'accept',
      };

    '100 allow steam client':
      opts => {
        chain => 'PUPPET-OUTPUT',
  proto       => 'udp',
  dport       => 26900,
  action      => 'accept',
      };
  }


  user { 'ocfcsgo':
    comment => 'Counter-Strike Server',
    home    => '/opt/csgo',
    groups  => ['sys'],
    shell   => '/bin/false';
  }

  file {
    default:
      owner => ocfcsgo,
      group => ocfcsgo;

    ['/opt/csgo', '/opt/csgo/bin', '/opt/csgo/etc']:
      ensure => directory,
      mode   => '0755';

    '/opt/csgo/bin/update-csgo':
      source => 'puppet:///modules/ocf_csgo/bin/update-csgo',
      mode   => '0755';

    '/opt/csgo/etc/csgo-update.cmd':
      source => 'puppet:///modules/ocf_csgo/etc/csgo-update.cmd';
  }

  package {
    'lib32gcc1':;
  }

  exec {
    'download-steamcmd':
      command => 'curl http://media.steampowered.com/installer/steamcmd_linux.tar.gz | tar xzf - -C /opt/csgo/bin',
      user    => ocfcsgo,
      creates => '/opt/csgo/bin/steamcmd.sh',
      notify  => Exec['update-csgo'],
      require => File['/opt/csgo/bin'];

    'update-csgo':
      command     => '/opt/csgo/bin/update-csgo',
      user        => ocfcsgo,
      refreshonly => true,
      require     => [File['/opt/csgo/bin/update-csgo'], Package['lib32gcc1']],
      notify      => Ocf::Systemd::Service['srcds'];
  }

  ocf::systemd::service { 'srcds':
    source  => 'puppet:///modules/ocf_csgo/srcds.service',
    require => [File['/opt/csgo/bin']],
  }

  ocf::munin::plugin { 'csgo':
    source => 'puppet:///modules/ocf_csgo/munin';
  }
}
