perl -e '
    use strict;
    use warnings;
    no warnings "uninitialized";
    use English qw( -no-match-vars );

    my @lines;
    my $element = $ARGV[0];
    my $command = q{<%= @read_command %> 2>&1};
    my $raw = qx{$command};
    if ( $CHILD_ERROR ) {
        die sprintf(
            "Error reading defaults.\nCommand: %s\nExit status: %d.\nOutput:%s",
            $command,
            $CHILD_ERROR,
            $raw,
        );
    }

    foreach my $line (split("\n", $raw)) {
        # Remove leading spaces and double quotes, and trailing double quotes,
        # commas, and spaces.
        $line =~ s/(?:\A\s+?"|",?\s*?\z)//g;
        push(@lines, $line);
    }
    @lines = splice(@lines, 1, -1);
    if ( $ARGV[1] eq "--exclude" ) {
        @lines = grep { $_ ne $element } @lines;
    } elsif ( $ARGV[1] eq "--exists" ) {
         @lines = grep { $_ eq $element } @lines;
         exit(@lines ? 0 : 1);
    } elsif ( $ARGV[1] eq "--existsat" ) {
        my $idx = $ARGV[2];
        exit( scalar(@lines) > $idx && $lines[$idx] eq $element ? 0 : 1 );
    }
    print join(" ", map { "\047$_\047" } @lines);
' --