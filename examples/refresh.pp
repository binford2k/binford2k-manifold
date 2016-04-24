manifold { 'internal':
  type         => 'exec',
  match        => 'tag',
  pattern      => 'internal',
  relationship => notify,
}

exec { ['foo', 'bar', 'baz']:
  command     => "/bin/echo 'it ran'",
  logoutput   => true,
  refreshonly => true,
  tag         => 'internal',
}

yumrepo { 'internal':
  ensure   => 'present',
  baseurl  => 'file:///var/yum/mirror/centos/7/os/x86_64',
  descr    => 'Locally stored packages for base_local',
  enabled  => '1',
  gpgcheck => '0',
  priority => '10',
  before   => Manifold['internal'],
}
