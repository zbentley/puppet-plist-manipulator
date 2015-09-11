# plist

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)

## Overview

A one-maybe-two sentence summary of what the module does/what problem it solves.
This is your 30 second elevator pitch for your module. Consider including
OS/Puppet version it works with.

## Module Description

If applicable, this section should have a brief description of the technology
the module integrates with and what that integration enables. This section
should answer the questions: "What does this module *do*?" and "Why would I use
it?"

If your module has a range of functionality (installation, configuration,
management, etc.) this is the time to mention it.

## Documentation todos
- Why perl?

- Why this and not other libs?
	Other libs poorly documented
	Poor tests; this has loads, for use hacking onit, and acceptance tests! (osx only).
	Too fragile dependent on weird system libs, CFPlist; this module sticks as close as possible to pure Puppet.
	No puppet-uniqueness/global lockin
	Robust array manipulation support
	Robust dictionary manipulation support

Known issues:
- Resources can be redeclared if the same plist is addressed with plistfile and without.

TODOs:
	- Make array-items perform type assertions. 
	- Fix unit tests.
	- Consider removing the distinction between array/dict and array-item/dict-item; infer backend heruistically based on $value.
	- Tests for ensure empty-present on "array" "dict" "dictionary".
	- Tests for "traditional" types.
	- Make a dict-item class
	- Implement "atposition" for non append/prepend cases.
	- Remove ensure => exists support from array item.
	- Git remove sublime history files.

Post-release todos:
	- Before/after positionals?
	- Before/after recipes using puppet builtin before/after.
	- Identity/puppet deduplication support.


Array Presence operations:
	ensure that an item is in position X; if it exists anywhere in the list do nothing:
	this is the only truly idempotent option
		ensure => "present" or "exists"
		before/after/append/prepend =>

	ensure that an item is in position X; delete all instances of it not in that position:
	this is not idempotent, but usually will end up being idempotent
		ensure => "once"
		before/after/append/prepend =>

	ensure that an item is in position X; if it exists in the wrong position duplicate it: 
	this is not idempotent, and will *often* make changes. append/prepend translate conceptually into "ensure => last" or "ensure => first".
	it will *always* make changes if you do value => "foo" after => "some constant" or append => true
		ensure => "atposition"
		before/after/append/prepend =>

Array Absence operations:
	ensure that the item does not exist at position X
	this is eventually idempotent (i.e. if you have a b b b) and ensure absent after => b, it'll modify 3 times before finishing.
		ensure => absent
		before/after/append/prepend =>

	ensure that the item does not exist anywhere:
		ensure => absent
