/usr/bin/perl -e '
    use strict;
    use warnings;
    use Data::Dumper;
    no warnings "uninitialized";
    use English qw( -no-match-vars );

    my @lines;
    my $element = $ARGV[0];
    sub run_command {
        my $command = shift(@_);
        my $raw = qx{$command 2>&1};
        if ( $CHILD_ERROR ) {
            die sprintf(
                "Error reading defaults.\nCommand: %s\nExit status: %d.\nOutput:%s",
                $command,
                $CHILD_ERROR,
                $raw,
            );
        }
        return $raw;
    }

    my $raw = run_command(q#<%= @read_command %>#);

    foreach my $line (split("\n", $raw)) {
        # Remove leading spaces and double quotes, and trailing double quotes,
        # commas, and spaces.
        $line =~ s/\A\s+|\s+\z//g;
        $line =~ s/\A"(.+)?",?\z/$1/g;
        $line =~ s/,\z//g;
        push(@lines, $line);
    }
    @lines = splice(@lines, 1, -1);
    if ( $ARGV[1] eq "--exclude" ) {
        @lines = grep { $_ ne $element } @lines;
    } elsif ( $ARGV[1] eq "--prepend" ) {
        unshift(@lines, $element);
    } elsif ( $ARGV[1] eq "--exists" ) {
        foreach my $line (@lines) {
            exit 0 if $line eq $element;
        }
        exit 1;
    } elsif ( $ARGV[1] eq "--existsat" ) {
        my $idx = $ARGV[2];
        exit( scalar(@lines) > $idx && $lines[$idx] eq $element ? 0 : 1 );
    }
    run_command(q#<%= @write_command %> # . join(" ", map { "\047$_\047" } @lines));
' --