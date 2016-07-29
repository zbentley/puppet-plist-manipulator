# puppet-plist-manipulator

An **unfinished** [puppet](https://docs.puppetlabs.com/puppet/latest/reference/architecture.html) module for manipulating `defaults` settings and `.plist` files for OSX, with minimal dependencies, support for array manipulation, basic key/value management, and thorough acceptance tests.

## Overview

**Disclaimer:** this software is **incomplete, unfinished, and not ready for use on systems where you care about your preference data.** It is not yet tagged for release; see the "Incompleteness" section for more info.

Most of the documentation is stubby, too. As I write more, the items below will become [links]().

- Quick Start
- Detailed installation guide
- Usage Examples
- Full `plist::item` documentation

## Goals
- `puppet-plist-manipulator` is designed to be a one-stop-shop for  [Puppet](https://docs.puppetlabs.com/puppet/latest/reference/architecture.html) code that, for any reason, needs to interact with data stored in a [`.plist`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man5/plist.5.html) file on OSX and/or data exposed through the OSX  [`defaults`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/defaults.1.html) utility.
- This module tries to be a superset of all existing plist-manipulation-via-Puppet functionaliy behind a single API. It supports the *general* goal of "I want to change key X in preference-identifier/file Y" for any combination of X and Y, rather than trying to accomplish a narrow goal ("I want to manage the preferences for application A, which will always comply with a given schema").
- This module makes no assumptions about your deployment environment. You may be using [boxen](https://github.com/boxen), [librarian-puppet](https://github.com/rodjek/librarian-puppet), [r10k](https://github.com/puppetlabs/r10k), rubygems, or some other framework to deploy and manage puppet code . . . or you may not, and may choose to put code into your Puppet setup by hand. No installation approach should be required by this module. 
- As such, it keeps dependencies to a minimum. It requires no additional gems to function, and depends only on Puppet's core functionality and the Perl that comes installed by default on OSX (running the tests does require some Ruby tooling, though).

#### Benefits of `puppet-plist-manipulator`

- It supports limited manipulation of `array`-type dictionary keys in-place, rather than overwriting the entire array. This is useful for interacting with `.plist` files that are only partially managed by Puppet.
- It has thorough unit tests.
- It has thorough acceptance tests. It uses a bastardized version of [serverspec](http://serverspec.org/)'s full-puppet-lifecycle tests on a local OSX to manage real preferences/defaults/`.plist` files. The ability to do this is unique to this module, so far as I can tell (I may well be wrong).

#### Drawbacks of Existing Modules

There are lots of Puppet modules for interacting with `.plist` files/OSX settings/`defaults` out there. However, many/most of those modules have significant drawbacks/issues:

- A lot of them are single-purpose--designed for interacting with one type of plist in one way.
- Many lack thorough more-than-unit tests (some don't have tests at all).
- Many of them lack acceptance tests/proof that they will work (or not mangle existing `.plist` files if handed the wrong value). Some don't have tests at all.
	- In a tool to automatedly alter arbitrary internal configuration data on a customized OSX workstation, tests to prove that data is not lost or broken are not an optional feature.
	- The fact that this module provides *acceptance* tests (not just unit tests) is extremely useful--both for proving that data won't get mangled, and for facilitating rapid development on this module. Since the external/black-box behavior is reasonably well specified and asserted by the acceptance tests, head-scratching about the effects of changes to the code is substantially reduced. Granted, the acceptance test system is kind of a hack, but it serves the needed purpose, and is better than nothing.
- Many existent modules fail in common edge cases (like writing multiline values to a key, adding/removing keys progressively, or writing special characters).
- Existing modules are often poorly documented.
- Existing modules are often dependent on gems/user-installed libraries that are difficult to configure. [CFPropertyList](https://rubygems.org/gems/CFPropertyList), for example, is [very difficult to get working for Puppet on OSX](https://github.com/glarizza/puppet-property_list_key). This module has a goal of being as close to dependency-free as possible, and as easy to install as possible, regardless of your Puppet/deployment setup.
- Existing modules can't easily manipulate individual array/dictionary keys in a `.plist` file value.

## Incompleteness

This module isn't finished yet. See `TODO.md` for more information on missing features (once that backlog is reduced, I'll move the remaining action items into GitHub issues).

The most notable missing features are a lack of support for managing `dict`-type items, and lacks support for managing more than one item per module in Puppet. The most notable technical deficiencies are that it uses a templated Perl script to interact with `defaults`, doesn't support management of arbitrary non-preference `.plist` files, and is not yet properly packaged for distribution via any system (e.g. [forge](https://forge.puppetlabs.com/), or [r10k](https://github.com/puppetlabs/r10k)).

## Other Resources/Reading

https://engineering.opendns.com/2014/11/13/testing-puppet-modules-vagrant-serverspec/
https://github.com/glarizza/puppet-property_list_key
https://github.com/boxen/puppet-osx
https://github.com/pebbleit/puppet-macdefaults
https://github.com/wfarr/puppet-osx_defaults
https://github.com/mosen/puppet-plist
