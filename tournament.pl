#!/usr/bin/perl5

# use strict;
use warnings;
use Data::Dumper;

use Text::CSV::Simple; #http://search.cpan.org/~tmtm/Text-CSV-Simple-1.00/lib/Text/CSV/Simple.pm

#import csv and convert to an array of hashes
my $Parser = Text::CSV::Simple->new;
$Parser->field_map(qw/name serve_accuracy serve_spin return_skill return_accuracy return_spin notes/);
my @Data = $Parser->read_file("data.csv");
shift @Data;

#list of games
my @Games = ([0,1],[0,2],[1,2]);


#call game
sub pick_match {
  print "\033[2J";   #clear the screen
  print "\033[0;0H"; #jump to 0,0
  my @game_on;
  if (@Games){
    @game_on = @{shift @Games};
    start_game($game_on[0],$game_on[1]);
  } else {
    print "all games done";
  }
}


#main
sub start_game {
  #initialize players
  my ($p1, $p2) = @_;
  my %player_one = %{$Data[$p1]};
  my %player_two = %{$Data[$p2]};

  $player_one{"score"} = 0;
  $player_two{"score"} = 0;

  print ("Game Time! $player_one{name} vs. $player_two{name}\n");

  print("[Press 'Enter' to start the match]");
  <STDIN>;

  #determine who serves first (toss coin)
  my $first_serve = int rand (2) eq 0 ? $p1 : $p2;
  print("Coin Toss!");
  <STDIN>;

  if ($p1 eq $first_serve){
    print ("$player_one{name} is the first server\n");
    <STDIN>;
    serve(\%player_one, \%player_two);
  } elsif ($p2 eq $first_serve){
    print ("$player_two{name} is the first server\n");
    <STDIN>;
    serve(\%player_two, \%player_one);
  }

}

my $lastserved = '';
my $lastlastserved = '';

#server serves
sub serve {
  my ($p, $o) = @_;
  my %pl = %{$p};
  my %op = %{$o};
  my $serve;

  if ($lastlastserved eq $pl{name}){
    print ("$op{name} is serving ");
    $serve = (rand (100) le $op{serve_accuracy}) ? 'true' : 'false';
    $lastserved = $op{name};
    $lastlastserved = '';
    if ($serve eq 'true'){
      print "...in-bounds\n";
      return_back(\%pl, \%op);
      } else {
      print "...out of bounds\n";
      &update_score (\%pl,\%op);
    }
  }
  elsif ($lastlastserved eq $op{name}){
    print ("$pl{name} is serving ");
    $serve = (rand (100) le $pl{serve_accuracy}) ? 'true' : 'false';
    $lastserved = $pl{name};
    $lastlastserved = '';
    if ($serve eq 'true'){
      print "...in-bounds\n";
      return_back(\%op, \%pl);
      } else {
      print "...out of bounds\n";
      &update_score (\%pl,\%op);
    }
  }
  elsif ($lastserved eq $pl{name}){
    print ("$pl{name} is serving ");
    $serve = (rand (100) le $pl{serve_accuracy}) ? 'true' : 'false';
    $lastlastserved = $pl{name};
    if ($serve eq 'true'){
      print "...in-bounds\n";
      return_back(\%op, \%pl);
      } else {
      print "...out of bounds\n";
      &update_score (\%pl,\%op);
    }
  }
  elsif ($lastserved eq $op{name}){
    print ("$op{name} is serving ");
    $serve = (rand (100) le $op{serve_accuracy}) ? 'true' : 'false';
    $lastlastserved = $op{name};
    if ($serve eq 'true'){
      print "...in-bounds\n";
      return_back(\%pl, \%op);
      } else {
      print "...out of bounds\n";
      &update_score (\%pl,\%op);
    }
  }
  else {
    print ("$pl{name} is serving ");
    $serve = (rand (100) le $pl{serve_accuracy}) ? 'true' : 'false';
    $lastserved = $pl{name};
    if ($serve eq 'true'){
      print "...in-bounds\n";
      return_back(\%op, \%pl);
      } else {
      print "...out of bounds\n";
      &update_score (\%pl,\%op);
    }
  }
}

#receiver returns with serve spin factor
sub return_back {
  my ($p, $o) = @_;
  my %pl = %{$p};
  my %op = %{$o};
  print ("$pl{name} returning to $op{name} ");
  my $return = (rand (100) le (($pl{return_skill} - $op{serve_spin}) * $pl{return_accuracy})) ? 'true' : 'false';
  if ($return eq 'true'){
    print "...in-bounds\n";
    &return_forth(\%op, \%pl);
    } else {
    print "...out of bounds\n";
    &update_score (\%pl,\%op);
  }
}

#server returns
sub return_forth {
  my ($p, $o) = @_;
  my %pl = %{$p};
  my %op = %{$o};
  print ("$pl{\"name\"} returning to $op{\"name\"} ");
  my $return = (rand (100) le (($pl{return_skill} - $op{return_spin})* $pl{return_accuracy})) ? 'true' : 'false';
  if ($return eq 'true'){
    print "...in-bounds\n";
    &return_back2(\%op, \%pl);
    } else {
    print "...out of bounds\n";
    &update_score (\%pl,\%op);
  }
}

#receiver returns WITHOUT serve spin factor anymore
sub return_back2 {
  my ($p, $o) = @_;
  my %pl = %{$p};
  my %op = %{$o};
  print ("$pl{name} returns to $op{name} ");
  my $return = (rand (100) le (($pl{return_skill} - $op{return_spin}) * $pl{return_accuracy})) ? 'true' : 'false';
  if ($return eq 'true'){
    print "...in-bounds\n";
    &return_forth(\%op, \%pl);
    } else {
    print "...out of bounds\n";
    &update_score (\%pl,\%op);
  }
}

#updates scores
sub update_score {
  my ($p, $o ) = @_;
  my %pl = %{$p};
  my %op = %{$o};
  $op{score} += 1;
  print ("  Score: $pl{\"name\"}, $pl{\"score\"} and $op{\"name\"}, $op{\"score\"}\n");
  if ($op{score} == 10 && $pl{score} == 10){
    $op{score} = 9;
    $pl{score} = 9;
    print ("  Deuce: $pl{\"name\"}, $pl{\"score\"} and $op{\"name\"}, $op{\"score\"}\n");
    <STDIN>;
    serve(\%pl,\%op);
  } elsif ($op{score} < 11) {
    <STDIN>;
    serve(\%pl,\%op);
  } else {
    print ("\n  $op{\"name\"} wins\n\n");
    summary($op{name},$pl{name});
    print("\n\n[Press 'Enter' for next match]");
    <STDIN>;
    $lastserved = '';
    $lastlastserved = '';
    &pick_match;
  }
}

my @players = ([$Data[0]{name},0,0],[$Data[1]{name},0,0], [$Data[2]{name},0,0]);

sub summary {
  my $w = shift;
  my $l = shift;

  for my $i (0..$#players){

      if ($players[$i][0] eq $w){
        $players[$i][1] += 1;
      }

      if ($players[$i][0] eq $l){
        $players[$i][2] += 1;
      }
  }
  print ("score recap:\n");
  for my $j (0..$#players){
    print ("$players[$j][0], $players[$j][1] - $players[$j][2]\n");
    }
  return;
}

#run
pick_match;
