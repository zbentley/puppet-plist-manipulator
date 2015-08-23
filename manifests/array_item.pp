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

	$position = str2bool($append) ? {
		true    => "last",
		false => "first"
	}

	if ! ( $ensure in ["present", "exists", "once", "atposition", "absent"] ) {
		fail("'ensure' must be 'once', 'present', 'exists', 'atposition' or 'absent'.")
	} elsif $ensure == "absent" {
		fail ("TOOODO")
		if $append != undef {
			fail("'append' cannot be combined with ensure => 'absent'.")
		} else {
			# TODO ensure absent before, after (index?)
			exec { "Remove existing entries":
				command => "${sanitizecmd} --value '${value}' --exclude",
				# Only remove entries if they exist.
				onlyif => "${sanitizecmd} --value '${value}' --exists";
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