define plist::array_item (
	$ensure,
	$value,
	$read_command,
	$write_command,
	$append_command,
	$append = false,
	$before_element = undef,
	$after_element = undef,
) {
	# ZBTODO add tests for this.
	assert_private("plist::array-item is private; use plist::item instead.")
    validate_bool($append)
    validate_re($ensure, "^(?:present|exists|once|atposition|absent)$")
    validate_string($value, $read_command, $write_command, $append_command)

    # ZBTODO add support.
    if $before_element != undef or $after_element != undef {
        fail("'before_element' and 'after_element' are not yet supported.")
    }

	Exec {
		logoutput => "on_failure",
		provider => "shell"
	}

	# Use a template to get the script. We don't need a file resource created
	# on the system, so we don't declare a File, and besides: the file() function
	# doesn't work with relative paths. The template() function does, however.
	$sanitizecmd = template("plist/array_manipulator.pl")

	$position = $append ? {
		true    => "last",
		false => "first"
	}

	if $ensure == "absent" {
		if $append {
			fail("'append' cannot be combined with ensure => 'absent'.")
		} else {
			# TODO ensure absent before, after (index?)
			exec { "Remove existing entries":
				command => "${sanitizecmd} '${value}' --exclude",
				# Only remove entries if they exist.
				onlyif => "${sanitizecmd} '${value}' --exists";
			}
		}
	} elsif $ensure == "present" or $ensure == "exists" {
		exec { "Install new value":
			command => "${sanitizecmd} '${value}' --${position}",
			# Only install entries if they are not in the array.
			unless => "${sanitizecmd} '${value}' --exists";
		}
	} else { # ensure is "atposition" or "once"
		if $ensure == "once" {
			exec { "Remove previous entries before installing new one":
				command => "${sanitizecmd} '${value}' --exclude",
				# Ensures proper ordering.
				before => Exec["Install new value"],
				# Only remove previous entries if they exist at non-desired positions in the list.
				onlyif => "${sanitizecmd} '${value}' --exists && ! ${sanitizecmd} '${value}' --existsat ${position}";
			}
		}
		exec { "Install new value":
			command => "${sanitizecmd} '${value}' --${position}",
			unless => "${sanitizecmd} '${value}' --existsat ${position}";
		}
	}
}