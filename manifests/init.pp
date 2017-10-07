# Authors
# -------
#
# Daniel Wittenberg <dan.wittenberg@thinkahead.com>
#
# Copyright
# ---------
#
# Copyright 2017 Ahead LLC, unless otherwise noted.
#
# @param url URL for API integration

class report2snow (
  Stdlib::Httpsurl $url,
  Stdlib::Httpsurl $puppet_console,
  String $debug = false
) {
  pe_ini_setting { "${module_name}_enable_reports":
    ensure  => present,
    path    => "${settings::confdir}/puppet.conf",
    section => 'agent',
    setting => 'report',
    value   => true,
  }

  pe_ini_subsetting { "${module_name}_report_handler" :
    ensure               => present,
    path                 => "${settings::confdir}/puppet.conf",
    section              => 'master',
    setting              => 'reports',
    subsetting           => $module_name,
    subsetting_separator => ',',
    notify               => Service['pe-puppetserver'],
  }

  file { "${settings::confdir}/${module_name}.yaml":
    ensure  => present,
    owner   => 'pe-puppet',
    group   => 'pe-puppet',
    mode    => '0644',
    replace => false,
    content => epp("${module_name}/${module_name}.yaml.epp"),
  }
}
