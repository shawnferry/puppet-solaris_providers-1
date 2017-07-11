# Provide addtional tooling for zones to use templates and
# structured data
class solaris_providers::zone {
  # solaris_providers::zone::zones
  # Array of zones to create in hash form
  $zones = lookup('zones')
  $zones.each |Hash $zone| {
    notify{"${zone}":}
    zone { $zone['zonename']:
      ensure         => $zone['state'],
      zonepath       => $zone['zonepath'],
      install_args   => epp('solaris_providers/zone/install_args.epp',
      {'zone_data'   => $zone}),
      zonecfg_export => epp('solaris_providers/zone/zonecfg_export.epp',
      { 'fields'     => $facts['solaris_providers::zone::zonecfg_export_fields'],
        'zone_data'  => $zone }),
      sysidcfg       => epp('solaris_providers/zone/sysidcfg.epp',
      { 'zone_data'  => $zone})
    }
  }
}
