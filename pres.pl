#!/usr/local/bin/perl -w
use strict;
use Text::CSV;

my $csv = Text::CSV->new;
my $row = $csv->getline(\*ARGV);
my @candidates;
my %state_ev;
my %state_result;

@candidates = @{$row}[2..$#$row];

print STDOUT ("Candidates are: ", join(", ", @candidates), "\n");

while (defined ($row = $csv->getline(\*ARGV))) {
    my ($state, $ev);
    my (@dhondt);
    my (@electors);
    $state = shift @$row;
    $ev = shift @$row;

    # To remove the "rural state bonus" in electors, uncomment this line.
    # $ev -= 2;
    foreach my $candidate (0..$#$row) {
	$state_ev{$state} = $ev;
	$dhondt[$candidate] = [];
	$electors[$candidate] = 0;

	foreach my $divisor (0..($ev - 1)) {
	    my $quotient = int($row->[$candidate] / ($divisor + 1));
	    $dhondt[$candidate]->[$divisor] = $quotient;
	}
    }

    foreach my $elector (1..$ev) {
	my $winner = 0;
	my $winning_candidate;
	foreach my $candidate (0..$#$row) {
	    if ($dhondt[$candidate]->[0] > $winner) {
		$winner = $dhondt[$candidate]->[0];
		$winning_candidate = $candidate;
	    }
	}
	shift @{$dhondt[$winning_candidate]};
	$electors[$winning_candidate]++;
    }
    $state_result{$state} = [@electors];

    print STDOUT "$state ($ev):";
    foreach my $candidate (0..$#$row) {
	if ($electors[$candidate] > 0) {
	    print STDOUT " $candidates[$candidate] ($electors[$candidate])";
	}
    }
    print STDOUT "\n";
}

my @totals;
my $tot_ev = 0;
foreach my $state (keys %state_result) {
    $tot_ev += $state_ev{$state};
    foreach my $candidate (0..$#candidates) {
	$totals[$candidate] = 0 unless(defined $totals[$candidate]);
	$totals[$candidate] += $state_result{$state}->[$candidate] || 0;
    }
}

print STDOUT "Total ($tot_ev): ";
foreach my $candidate (0..$#candidates) {
    if ($totals[$candidate] > 0) {
	print STDOUT " $candidates[$candidate] ($totals[$candidate])";
    }
}
print STDOUT "\n";
