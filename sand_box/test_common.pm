#package Common;



use 5.010;
use strict;
use warnings;
use diagnostics;

our $VERSION = '0.01';

our %Aminolist;
our %Rules;
1;
# select data file from current directory
sub GetDataFile {
	my $Input; # declare new scalar 'Input'
	my @files = glob("*.txt"); # declare new array glob("*.txt") double quotes means interpretted string
	# glob(EXPR_1 EXPR_2) returns an array of filename expansions on the value of EXPR just as the standard
	# Unix shell /bin/csh would do. In scalar context, glob iterates through such filename expansions, 
	# returning undef when the list is exhausted.
	do {
		print "Select Data File\n"; # prints instructions to the user
		for (my $i=0;$i<@files;$i++) { # iterates through all the files in the array
			print "[$i] $files[$i] \n"; # prints the files along with the index
		}
		$Input = <STDIN>;	# takes input from user
	} while (! exists  $files[$Input]); # if the the stated index not a member of the list, loop back to beginning
	return $files[$Input]; # otherwise return the scalar (string) corresponding to the filename
}

#Load Amino Database
sub LoadData {
	my $Fname = GetDataFile(); # scalar = GetDataFile() output (path to user selected file)
	%Aminolist = (); # initialize hash 
	open (DATA,$Fname) or die "Error: $!"; # open file with DATA handler
	my (@title) = split(/\t/,<DATA>); # split first line of specified file and set as array 'title'
	for my $line (<DATA>) {		# iterate over each line (as scalar) in specified file
		$line =~ s/\r?\n$//; # line (scalar) is equivalent each line in file separated by \n or \r carriage return characters
		my (@d) = split(/\t/,$line); # split scalar (line) at tab and store resulting substrings in the array d
		my %c = ("Code" => $d[0],"Ratio" => $d[2],"InUse" => 0); # create a new hash c with key "Code" matched to value aa_code, "Ratio" matched to frequency, and "InUse" to null value		
		#say %c; # This prints the hash
		# say $Aminolist{$d[1]}; # This prints the memory address to the array (the value of each key in the hash table Aminolist)
		#say %Aminolist; # This prints the hash table Aminolist
		push(@{$Aminolist{$d[1]}}, \%c); # A lot of functionality in this line. 1) sets the key equal to $d[1] 2) Create an array and appends all hash tables as items in the array that match the key
	} # populating the aminolist (hash table) with keys = aa ($d[1]) and values are hash %c
	#Aminolist is a hash of arrays. Each array is also a hash. The keys are strings (scalars). The array is stored as a pointer? when you print, you get memory address of first variable 
	close DATA;
	# sort Desending
	foreach my $key (keys %Aminolist) { # iterate through all keys (aa) in aminolist (hash)
		#say "\n";
		@{$Aminolist{$key}} = sort {$$b{"Ratio"} <=> $$a{"Ratio"}}  @{$Aminolist{$key}}; # build an ordered array of aa. sort numerically descending
	}
	return $Fname;
}

#Load Replacment rules
sub LoadRules {
	%Rules =(); # instantiate empty hash
	say %Rules;
	open (RULES,"Rules.rul") or die "Can't Find Rules: $!"; 
	my (@title) = split(/\t/,<RULES>);	
	say @title;
	for my $line (<RULES>) {
		$line =~ s/\r?\n$//;		
		say $line;
		my @d = split(/\t/,$line);			
		say @d;
		say @d[1.. @d-1];
		say $d[0];
		say sort(@d[1.. @d-1]);
		$Rules{join ('',sort(@d[1.. @d-1]))} = $d[0]; #join takes an array and joins them together with a specified string between each element
		# Binary ".." is the range operator, which is really two different operators depending on the context. Here, it returns a list of values counting (up by ones) from the left to the right value. If the left value is greater than the right value, then it returns an empty list
	}
	say %Rules;
	say keys %Rules;
	say "\n\n\n";
	close RULES;	
}

sub BestList {
	my @list; # instantiate array structure
	for my $key (keys %Aminolist) { # iterate through keys in %Aminolist (with deleted aa's selected by user)
		if ((scalar @{$Aminolist{$key}})>1) { # if there are more than one codon for the amino acid (list length > 1)
			my $c = {"Ratio"=>0,"Code"=>""}; # new scalar (pointer to 'empty' hash).  
			#say %$c;
			for my $x (@{$Aminolist{$key}}) { # iterate through the hash items in the list
				#say %$x;
				#say $$x{"Ratio"};
				#say $$c{"Ratio"};
				if ($$x{"Ratio"}>$$c{"Ratio"} && $$x{"InUse"}==0) { # assign hash c key 'ratio' to highest value codon usage frequency
					$c=$x; # set the c hash equal to the x hash (the one with highest frequency usage)
				}
				#say $$x{"Ratio"};
				#say $$c{"Ratio"};
			}
			#say $$c{"Code"};
			#say %$c;
			#say "\n\n\n";
			if ($$c{"Code"} ne "") { # ne is perl string inequality (equivalent to != for numeric inequality).
				$$c{"InUse"}=1; # assign InUse key to 1
				push (@list,$$c{"Code"}); # append this codon to the array 'list'
			}
		}
		else { # if there are not more than one entry in the list (i.e. only one codon for that aa)
			my $c = ${$Aminolist{$key}}[0]; # new scalar (pointer) to hash 'c' that contains key-value pair identical to the single codon.
			if ($$c{"InUse"}==0) {
				$$c{"InUse"}=1; # set InUser to 1
				push(@list,$$c{"Code"}); # append this codon to the array 'list'
			}
		}
	}
	return @list; # retun the list of highest frequency usage codons.
}

sub Grouping {
	my ($list,$GroupBy) = @_; # $list is the pointer to array passed to Reduce. $GroupBy is an integer 0, 1, 2
	say "From Grouping: ";
	say $_[0]; # $_[0] == $list
	say $_[1]; # $_[1] == $GroupBy
	my %g=(); # instantiate empty hash
	for my $x (@{$list}) {	# dereference the array and iterate through it
		say "From Grouping loop 1: ";
		say $x; # each element in array
		my $y = substr($x,$GroupBy,1,''); # substr EXPR, OFFSET, LENGTH, REPLACEMENT. Extracts a substring out of EXPR and returns it. First character is at offset zero. If OFFSET is negative, starts that far back from the end of the string.
		say $y; # new string (depending on the value of $GroupBy, this gives the first, middle, or last character of string $x)
		my $InRules=0; # instantiate new scalar
		say %Rules;
		foreach my $l (keys %Rules) { # iterate over keys in %Rules
			say "From Grouping loop 2: ";
			say $l; # keys from %Rules
			say $Rules{$l}; # values from %Rules
			if ($Rules{$l} eq $y) { # if key == $y (sliced string)
				push (@{$g{$x}},split(//,$l));
				$InRules = 1;
			}
		}
		push(@{$g{$x}},$y) if (!$InRules);
		say "End Grouping loop 1: ";
		say @{$g{$x}};
		
	}
	for (keys %g) {
		$g{$_} = join('',sort(@{$g{$_}}));
	}	
	return %g;	
}

sub ListFromGroup {
	my ($g,$index) = @_;
	my @list;	
	for my $x  (keys %{$g})  {
		my $v = $x;							
		if (length($g->{$x}) >1) {
			substr($v,$index,0)=$Rules{$g->{$x}};
		}
		else {
			 substr($v,$index,0)=$g->{$x} ;				
		}
		push(@list,$v);
	}
	return @list;	
}

sub Reduce {
	my @a = @_; # @_ is the list that was passed as argument. capturing this as @a (local array)
	say "from Reduce: ";
	say $_[0]; # the first index item in the array (which was passed to this function)
	say @a;
	print "\n";
	for my $i (0..2) {	# iterate through integers 0, 1, 2	
		my %g = Grouping(\@a,$i); # pass @a by reference along with integers 0-2 to the Grouping sub-routine. Capture result in hash %g
		@a = ListFromGroup(\%g,$i);		
	}
	return @a;
}

sub FindMinList {
	my @a = Reduce(@_); # Pass the list that was passed to FindMinList to Reduce. capture result in @a 
	if (join('',@a) ne join('',@_)) {
		FindMinList(@a);
	}
	return @a;		
}



LoadData();
LoadRules();

my @wlist = BestList();
print @wlist;
print "\n";
print "List (" .(scalar @wlist) .")\n";
print join(", ",@wlist)."\n";
my @s = FindMinList(@wlist); # pass best list to FindMinList. Capture result in @s
print @s;
print "\n";



#print "Available amino acids (count: ". scalar (keys %Aminolist)." ,X represents stop codons)\n";
#print join( ',', keys %Aminolist )."\n";
#print "Choose amino acids to remove:\n";
#my  $a =  <STDIN>;
#print $a;
#chomp $a; # chomp removes any trailing string that corresponds to the current value of $/. It returns the total number of characters removed from all its arguments. By default $/ is set to newline character
#print $a;

#foreach my $key (keys %Aminolist) {
#	say "The key is: " . $key;
#	say "The value is: " . $Aminolist{$key};
#	my $array_ref = $Aminolist{$key};
#	print "The de-referenced value is: ";
#	say @$array_ref;
#	print "The de-referenced hashes are: ";
#	foreach (@$array_ref) {
#		my $hash_ref = $_;
#		print %$hash_ref;
#		print " ";
#	}
#	print "\n";
#	say @{$Aminolist{$key}};
#}

#say %Aminolist;

#LoadRules();













