# Public: Set a system config option with the OS X defaults system
define plist::item (
  $key, # relevant only to commands
  $ensure      =  "present",
  $value       = undef,

  $type        = undef, # relevant only to dispatcher. all core types, minus the -add types, plus array-item, dict-item

  $host        = "any", # relevant only to commands
  $domain      = undef, # relevant only to commands
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
    # boolean -> bool
    # int -> integer
    # str -> string
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
  # Assert-fail on invalid types. This is done in Puppet since the "defaults"
  # utility interprets invalid/nonsensical type signatures as -string.
  validate_re($_type, "^(?:dict|dict[-]item|array|array[-]item|boolean|float|integer|string)")
  validate_string($key, $host)
  if $append != undef {
    validate_bool($append)
  }
  if $key == undef or $host == undef {
    fail("'key' and 'host' cannot be undef.")
  }
  if $user != undef {
    validate_string($user)
  }

  if $domain != undef {
    validate_string($domain)
    if $plistfile {
      fail("Only one of 'domain' and 'plistfile' must be set (xor).")
    } else {
      $hostswitch  = $host ? {
        "currentHost" => "-currentHost",
        "current"     => "-currentHost",
        "any"         => "",
        "all"         => "",
        default       => "-host $host",
      }
      $cmd_root = "/usr/bin/defaults ${hostswitch}"
      $write_command = "${cmd_root} write ${domain} ${key}"
      $key_exists_command = sprintf(
        ' ( %s read %s %s 2> /dev/null ) ',
        $cmd_root,
        $domain,
        $key
      )
      $domain_exists_command = sprintf(
        ' ( echo " $(%s domains) " | grep -q " %s,* " ) ',
        $cmd_root,
        regsubst($domain, '[.]plist\z', "", 'GI')
      )
      # This is inelegant and probably a bug surface: check to see if the domain
      # exists in the list of available domains (with some silly spacing/quoting
      # manipulation). If so, ensure we can read it. If it doesn't exist, assume
      # it can be created.
      $key_writeable_command = "${domain_exists_command} && ${key_exists_command} || true"


      $type_assert_command = sprintf(
        "( %s read-type %s %s | grep -q ' %s' || ( echo Key '%s' exists, but is not of type '%s'; exit 1 ) )",
        $cmd_root,
        $domain,
        $key,
        $type,
        $key,
        $type
      )
    }
  } elsif ! $plistfile {
    fail("Only one of 'domain' and 'plistfile' must be set (xor).")
  } elsif $host != undef {
    fail("'host' cannot be combined with 'plistfile'.")
  } else {
    validate_absolute_path($plistfile)
    # ZBTODO plistbuddy support
    fail("'plistfile' is not implemented.")
  }

  # Array items are complex enough that their handling is delegated to a separate
  # module.
  if $_type == "array-item" {
    plist::array_item { "TODO" : # uniqueness-enforcing signatures will go here someday.
      ensure => $ensure,
      value => $value,
      append => $append,
      before_element => $before_element,
      after_element => $after_element,
      write_command => "${write_command} -array",
      read_command => $key_writeable_command,
      append_command => "${write_command} -array-add",
    }
  } elsif ! ( $ensure in ["present", "absent"] ) {
    fail("'ensure' must be 'present', or 'absent'.")
  } elsif $append != undef or $before_element != undef or $after_element != undef {
    fail("'append', 'before_element', and 'after_element' can only be used if 'type' is 'array-item'.")
  # Don't support any of the core defaults 'array' types.
  } elsif $_type =~ /^(array|dict)$/ and $ensure == "present" { # ensure => absent will be handled in the main case below.
    # Allow ensure present/absent on array/dict type elements without a value.
    if ( $value == undef ) {
      # Run the type assertion no matter what to surface "you're trying to ensure-present on something of the wrong type" errors.
      exec { "Install empty '${type}' element '${key}'":
        # If the key doesn't exist ($key_writeable_command only checks for that now, since the "unless" clause will prevent the command from
        # running if the key is already present with the right type), create it. Otherwise, fail the type assertion.
        command => "${key_writeable_command} && ${write_command} -${_type} || ${type_assert_command}",
        # Only create an empty array-type element if it doesn't exist with the right type.
        unless => "${key_writeable_command} && ${type_assert_command}";
      }
    } else {
      fail("'value' is not supported with 'array' or 'dict[ionary]' types; use 'array-item' or 'dict-item' instead")
    }
  }
  else {
    $single_write = "${write_command} -${_type} '${value}'"
    # ZBTODO assert value is defined
    # ZBTODO handle ensure absent

    # If the domain or key do not exist, write it
    # If the key exists and is the right type, write it
    # ZBTODO if the key exists with the wrong type and --force is set, write it
    # Else, fail with the type assertion

    exec { "Create '${key}' with '${value}' in '${domain}'":
      # A somewhat tortured way of writing "does it exist" ? "is it the right type" ? "write it" : "fail" : "write it".
      command => $single_write,
      # Don't do it if the element exists, is of the right type, and has the right value.
      unless => "${domain_exists_command} && ${key_exists_command}";
    }

    exec { "Set '${key}' to '${value}' in '${domain}'":
      command => "${type_assert_command} && ${single_write}",
      # Only run if the domain exists and the key isn't already the correct value.
      onlyif => "${domain_exists_command} && test '${value}' != $(${key_exists_command} | xargs echo -e)";
    }
  }
}