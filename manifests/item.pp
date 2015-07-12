# Public: Set a system config option with the OS X defaults system
define plist::item (
  $ensure      =  "present",
  $value       = undef,

  $type        = undef, # relevant only to dispatcher. all core types, minus the -add types, plus array-item, dict-item

  $host        = "currentHost", # relevant only to commands
  $domain      = undef, # relevant only to commands
  $key         = undef, # relevant only to commands
  $user        = undef, # relevant only to commands
  $plistfile = undef, # relevant only to commands

  $append = undef, # array only
  $before_element = undef, # array only
  $after_element = undef, # array only
) {
  $element = $value ? {
    undef => $title,
    default => $value,
  }

  Exec {
    logoutput => "on_failure",
    provider => "shell"
  }

  $xorfailuremessage = "'domain' and 'key' must both be set, and cannot be combined with 'plistfile' (xor)."
  if $domain != undef or $key != undef {
    if $plistfile or ! ( $domain != undef and $key != undef ) {
      fail($xorfailuremessage)
    } else {
      $write_command = "/usr/bin/defaults write ${domain} ${key}"
      $read_command = "/usr/bin/defaults read ${domain} ${key}"
    }
  } elsif ( ! $plistfile ) {
    fail($xorfailuremessage)
  } elsif $host != undef {
    fail("'host' cannot be combined with 'plistfile'.")
  } else {
    # TODO plistbuddy support
    fail("'plistfile' is not implemented.")
  }

  $signature = "TODO"

  if $type == "array-item" {
    plist::array_item { $signature :
      ensure => $ensure,
      value => $element,
      append => $append,
      before_element => $before_element,
      after_element => $after_element,
      write_command => "${write_command} -array",
      read_command => "${read_command} -array",
      append_command => "${write_command} -array-add",
    }
  } else {
    if ! ( $ensure in ["present", "absent", "once"] ) {
      fail("'ensure' must be 'once', 'present', or 'absent'.")
    } elsif $append != undef or $before_element != undef or $after_element != undef {
      fail("'append', 'before_element', and 'after_element' only apply if 'type' is 'array-item'.")
    }
    fail("TODO DODO")
    # Assert ensure as present or absent (array allows 'once').
    # Assert no array-only args.
  }

}