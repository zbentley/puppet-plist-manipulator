# Public: Set a system config option with the OS X defaults system
define plist::item (
  $ensure      =  "present",
  $value       = undef,

  $type        = undef, # relevant only to dispatcher. all core types, minus the -add types, plus array-item, dict-item

  $host        = undef, # relevant only to commands
  $domain      = undef, # relevant only to commands
  $key         = undef, # relevant only to commands
  $user        = undef, # relevant only to commands
  $plistfile = undef, # relevant only to commands

  $dictvalue = undef, # relevant only to dicts

  $append = undef, # array only
  $before_element = undef, # array only
  $after_element = undef, # array only
) {

  Exec {
    logoutput => "on_failure",
    provider => "shell"
  }

  # If no type is set, try to infer string, int, bool, or float.
  $_type = $type ? {
    "dictionary" => "dict", # -dictionary is not an allowed type signature.
    undef => $value ? {
      /^\d?[.]\d+$/ => "float",
      /^\d$/        => "integer",
      /^true$/      => "boolean",
      /^false$/     => "boolean",
      /^yes$/       => "boolean",
      /^no$/        => "boolean",
      default       => "string"
    },
    default => $type,
  }

  # Assert-fail on invalid types. This is done in Puppet since the defaults utility interprets invalid/nonsensical type signatures as -string.
  $validtypes = [ "dict", "dict-item", "array", "array-item", "boolean", "float", "integer", "string" ]
  if ! ( $_type in $validtypes ) {
    fail("Invalid type: ${type}. Valid types are: " + join($validtypes, ", "))
  }

  if $key == undef {
    fail("'key' must be set.")
  }

  $xorfailuremessage = "Only one of 'domain' and 'plistfile' must be set (xor)."
  if $domain != undef {
    if $plistfile {
      fail($xorfailuremessage)
    } else {
      $hostswitch  = $host ? {
        "currentHost" => "-currentHost",
        "current"     => "-currentHost",
        undef         => "",
        "any"         => "",
        "all"         => "",
        default       => "-host $host",
      }
      $cmd_root = "/usr/bin/defaults ${hostswitch}"
      $write_command = "${cmd_root} write ${domain} ${key}"
      # This is inelegant and probably a bug surface: check to see if the domain
      # exists in the list of available domains (with some silly spacing/quoting
      # manipulation). If so, ensure we can read it. If it doesn't exist, assume
      # it can be created.
      $read_command = sprintf(
        'echo " $(%s domains) " | grep -q " %s,* " && %s read %s %s || true',
        $cmd_root,
        regsubst($domain, '[.]plist\z', "", 'GI'),
        $cmd_root,
        $domain,
        $key
      )

      $type_assert_command = sprintf(
        "%s read-type %s %s | grep -q ' %s' || ( echo Key '%s' exists, but is not of type '%s'; exit 1 )",
        $cmd_root,
        $domain,
        $key,
        $type,
        $key,
        $type
      )
    }
  } elsif ! $plistfile {
    fail($xorfailuremessage)
  } elsif $host != undef {
    fail("'host' cannot be combined with 'plistfile'.")
  } else {
    # ZBTODO plistbuddy support
    fail("'plistfile' is not implemented.")
  }

  $signature = "TODO"

  # Array items are complex enough that their handling is delegated to a separate
  # module.
  if $_type == "array-item" {
    plist::array_item { $signature :
      ensure => $ensure,
      value => $value,
      append => $append,
      before_element => $before_element,
      after_element => $after_element,
      write_command => "${write_command} -array",
      read_command => $read_command,
      append_command => "${write_command} -array-add",
    }
  } elsif ! ( $ensure in ["present", "absent"] ) {
    fail("'ensure' must be 'present', or 'absent'.")
  } elsif $append != undef or $before_element != undef or $after_element != undef {
    fail("'append', 'before_element', and 'after_element' can only be used if 'type' is 'array-item'.")
  # Don't support any of the core defaults 'array' types.
  } elsif $type =~ /^array.+/ {
    fail("Type ${type} is not supported; use 'array-item' (for individual array elements) or 'array' (for addition/removal of array-type keys) instead.")
  } elsif $type =~ /^(array|dict|dictionary)$/ and $ensure == "present" { # ensure => absent will be handled in the main case below.
    # Allow ensure present/absent on array/dict type elements without a value.
    if ( $value != undef ) {
      fail("'value' is not supported with 'array' or 'dict[ionary]' types; use 'array-item' or 'dict-item' instead")
    } else {
      # Run the type assertion no matter what to surface "you're trying to ensure-present on something of the wrong type" errors.
      exec { "Install empty '${type}' element '${key}'":
        # If the key doesn't exist ($read_command only checks for that now, since the "unless" clause will prevent the command from
        # running if the key is already present with the write type), create it. Otherwise, fail the type assertion.
        command => "${read_command} && ${write_command} -${_type} || ${type_assert_command}",
        # Only create an empty array-type element if it doesn't exist with the right type.
        unless => "${read_command} && ${type_assert_command}";
      }
    }
  }
  else {
    # ZBTODO assert value is defined
    # ZBTODO handle ensure absent

    exec { "Set '${key}' to '${value}' in '${domain}'":
      command => "${type_assert_command} && ${write_command} -${_type} ${value}",
      # Don't do it if the element exists, is of the right type, and has the right value.
      unless => "${read_command} && ${type_assert_command}";
      # ZBTODO consider a "force" option here to just issue the write command.
    }
  }
}