# If before, after not set, just array-add it.
define plist::array_item (
	$ensure,
	$value,
	$read_command,
	$write_command,
	$append_command,
	$append = undef,
	$before_element = undef,
	$after_element = undef,
) {
	Exec {
		logoutput => "on_failure",
		provider => "shell"
	}
	# TODO add complicated command rationale
	# TODO switch everything to unlesses
	# TODO switch everything to complicated commands
	# TODO refresh attribute

	# TODO If the ensure is once with no other flags, dedup.

	# Use a template to get the script. We don't need a file resource created
	# on the system, so we don't declare a File, and the file() function
	# doesn't work with relative paths. The template() function does, however.
	$sanitizecmd = template("plist/array_manipulator.pl")

	if ! ( $ensure in ["present", "absent", "once"] ) {
		fail("'ensure' must be 'once', 'present', or 'absent'.")
	} elsif $ensure == "absent" {
		if $append != undef {
			fail("'append' cannot be combined with ensure => 'absent'.")
		} else {
			# TODO ensure absent before, after (index?)
			exec { "Remove existing entries":
				command => "${sanitizecmd} --value '${value}' --exclude | xargs ${write_command}",
				# Only remove entries if they exist.
				onlyif => "${sanitizecmd} --value '${value}' --exists";
			}
		}
	} else {
		if $before_element {
			# TODO before support
			fail("'before_value' is not implemented.")
		} elsif $after_element {
			# TODO after support
			fail("'after_value' is not implemented.")
		} elsif $append { # Append
			if $ensure == "once" {
				exec { "Remove previous entries before appending new one":
					command => "${sanitizecmd} '${value}' --exclude | xargs ${write_command}",
					# Ensures proper ordering.
					before => Exec["Append new value"],
					# Only remove previous entries if they exist.
					onlyif => "${sanitizecmd} '${value}' --exists";
				}
			}
			exec { "Append new value":
				command => "${append_command} \"${value}\"",
				# Only append entries if they exist and are not last.
				unless => "${sanitizecmd} '${value}' --existsat -1";
			}

		} else { # Prepend
			if $ensure == "once" {
				exec { "Remove previous entries before prepending new one":
					command => "${sanitizecmd} '${value}' --exclude | xargs ${write_command}",
					# Ensures proper ordering.
					before => Exec["Prepend new value"],
					# Only remove previous entries if they exist.
					onlyif => "${sanitizecmd} '${value}' --exists";
				}
			}
			exec { "Prepend new value":
				# Rationale for this convoluted command is at the top of this module.
				command => "out=$(${sanitizecmd}) || exit 1; echo \$out | xargs ${write_command} '${value}'",
				# Only prepend entries if they exist and are not first.
				unless => "${sanitizecmd} '${value}' --existsat 0";
			}
		}
	}
}