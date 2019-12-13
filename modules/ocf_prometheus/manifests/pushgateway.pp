class ocf_prometheus::pushgateway {
  class { '::prometheus::pushgateway':
    version     => '1.0.0'

  }
}
