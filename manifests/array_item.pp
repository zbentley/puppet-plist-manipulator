# If before, after not set, just array-add it.
define plist::array_item (
	$ensure,
	$domain = undef,
	$key = undef,
	$plistfile = undef,
	$value = undef,
	$append = undef,
	$before_element = undef,
	$after_element = undef,
) {
	# array_element:
	# 	domain
	# 	key
	# 	value # defaults to name
	# 	ensure # present|absent|once
	# 	append || # defaults to true
	# 	index (
	# 		insert?
	# 		unique?
	# 	) ||
	# 	before ( #Fails if before-val doesn't exist
	# 		unique?
	# 	) ||
	# 	after ( # fails if after-val doesn't exist
	# 		unique?
	# 	)
	# array:
	# 	elements


	# TODO add complicated command rationale
	# TODO switch everything to unlesses
	# TODO switch everything to complicated commands
	# TODO refresh attributeiter
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
			$write_command = "/usr/bin/defaults write ${domain} ${key} -array"
			$read_command = "/usr/bin/defaults read ${domain} ${key}"
			$append_command = "/usr/bin/defaults write ${domain} ${key} -array-add"
		}
	} elsif ( ! $plistfile ) {
		fail($xorfailuremessage)
	} else {
		# TODO plistbuddy support
		fail("'plistfile' is not implemented.")
	}

	# TODO If the ensure is once with no other flags, dedup.

	# Use a template to get the script. We don't need a file resource created
	# on the system, so we don't declare a File, and the file() function
	# doesn't work with relative paths. The template() function does, however.
	$sanitizecmd = template("plist/array_manipulator.pl")

	if ! ( $ensure in ["present", "absent", "once"] ) {
		fail("'ensure' must be 'once', 'present', or 'absent'.")
	} elsif $ensure == "absent" {
		if ( $append != undef ) {
			fail("'append' cannot be combined with ensure => 'absent'.")
		} else {
			# TODO ensure absent before, after (index?)
			exec { "Remove existing entries":
				command => "${sanitizecmd} --element '${element}' --exclude | xargs ${write_command}",
				# Only remove entries if they exist.
				onlyif => "${sanitizecmd} --element '${element}' --exists";
			}
		}
	} else {
		if $before_element {
			# TODO before support
			fail("'before_element' is not implemented.")
		} elsif $after_element {
			# TODO after support
			fail("'after_element' is not implemented.")
		} elsif $append { # Append
			if $ensure == "once" {
				exec { "Remove previous entries before appending new one":
					command => "${sanitizecmd} '${element}' --exclude | xargs ${write_command}",
					# Ensures proper ordering.
					before => Exec["Append new value"],
					# Only remove previous entries if they exist.
					onlyif => "${sanitizecmd} '${element}' --exists";
				}
			}
			exec { "Append new value":
				command => "${append_command} \"${element}\"",
				# Only append entries if they exist and are not last.
				unless => "${sanitizecmd} '${element}' --existsat -1";
			}

		} else { # Prepend
			if $ensure == "once" {
				exec { "Remove previous entries before prepending new one":
					command => "${sanitizecmd} '${element}' --exclude | xargs ${write_command}",
					# Ensures proper ordering.
					before => Exec["Prepend new value"],
					# Only remove previous entries if they exist.
					onlyif => "${sanitizecmd} '${element}' --exists";
				}
			}
			exec { "Prepend new value":
				# Rationale for this convoluted command is at the top of this module.
				command => "out=$(${sanitizecmd}) || exit 1; echo \$out | xargs ${write_command} '${element}'",
				# Only prepend entries if they exist and are not first.
				unless => "${sanitizecmd} '${element}' --existsat 0";
			}
		}
	}
}