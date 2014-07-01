#!/usr/bin/perl -w
#Written by W Brenna
#July 1 2014
#Licenced under GPLv2 - should be included in this repository.

if ($#ARGV < 1 ) {
		print STDERR "Usage: grTensorToMaxima.pl grTensorFileName cTensorFileName\n";
		exit 1;
}
open(FPTR,$ARGV[0]);
@grTensorFile = <FPTR>; #GrTensor file in array
close(FPTR);
print "The number of lines to be translated is ",$#grTensorFile + 1,".\n";
#print @grTensorFile;

#Set number of dimensions
@dimsString = grep(/^nDim/i,@grTensorFile);
#print $dimsString[0];
@nDimsVec = split(':=',$dimsString[0]);
$nDims = $nDimsVec[1];
$nDims =~ s/^\s+|\s+$//g;	#Trim off the whitespace
$nDims =~ s/\;?\:?//g;		#Strip off ending colon or semicolon
print "We are in ", $nDims," dimensions.\n";

$coordString = "ct_coords:[";
#Now get the coordinates
for (my $i=1; $i<$nDims+1; $i++) {
	if ($i > 1) {
		$coordString = $coordString . ",";
	}
	@coordEl = grep(/^x$i\_/i,@grTensorFile);
	@coordElVec = split(':=',$coordEl[0]);
	$coordTmp = $coordElVec[1];
	$coordTmp =~ s/^\s+|\s+$//g;
	$coordTmp =~ s/\;?\:?//g;
	$coordTmp =~ s/^\s+|\s+$//g;
	#print $coordTmp,"\n";
	$coordString = $coordString . $coordTmp;
}
$coordString = $coordString . "];";

$lgString = "lg:matrix([";
$dependsString = "depends([";
@dependsArr = ();
#Now, finally, set up the matrix.
for (my $i=1; $i<$nDims+1; $i++) {
	for (my $j=1; $j<$nDims+1; $j++) {
		if ($j > 1) {
			$lgString = $lgString . ",";
		}
		if (($i > 1) && ($j == 1)) {
			$lgString = $lgString . "],[";
		}
		@coordEl = grep(/^g$i$j\_/i,@grTensorFile);
		if (!@coordEl) {
			$lgString = $lgString . "0";
		}
		else {
			@coordElVec = split(':=',$coordEl[0]);
			$coordTmp = $coordElVec[1];
			$coordTmp =~ s/^\s+|\s+$//g;
			$coordTmp =~ s/\;?\:?//g;
			$coordTmp =~ s/^\s+|\s+$//g;
			#print $coordTmp,"\n";
			$coordTmp1 = $coordTmp;
			$coordTmp2 = $coordTmp;
			my @bracketedArray = $coordTmp2 =~ /((^|[\*\/\+\-])(?!sin|cos|tan|exp|sqrt|log|int|diff)[a-zA-Z\_]+  \( (?: [^\(\)]* | (?0) )* \) )/xg;
			my @bracketedFunction = $coordTmp1 =~ /((^|[\*\/\+\-])(?!sin|cos|tan|exp|sqrt|log|int|diff)[a-zA-Z\_]+) \( (?: [^\(\))]* | (?0) )* \)/xg;
			if (!@bracketedFunction) {
			}
			else {
				for (my $k=0; $k<$#bracketedFunction; $k++) {
					$bracketedArray[$k] =~ s/^.*\(//g;	#Remove to the left of the bracket
					$bracketedArray[$k] =~ s/\(?\)?//g;	#Remove enclosing brackets
					$bracketedFunction[$k] =~ s/^[\*\/\+\-]//g;
					$dependsArr[$#dependsArr+1] = $bracketedFunction[$k] . "],[" . $bracketedArray[$k] . "]);";
					#print $bracketedArray[$k] . "\n";
					#print $bracketedFunction[$k] . "\n";
				}
			}
			#print @bracketedArray . "\n";
			$coordTmp =~ s/(^|[\*\/\+\-])((?!sin|cos|tan|exp|sqrt|log|int|diff)[a-zA-Z\_]+)\((?:[^\(\)]++|(?0))*+\)/$1$2/g;	#Remove bracketed text
			#print $coordTmp . "\n";
			$lgString = $lgString . $coordTmp;
		}
	}
}
$lgString = $lgString . "]);";


#Now write it all to the file
open(my $writeFile, '>',$ARGV[1]) or die "Could not open output file '$ARGV[1]' $!";

print $writeFile "print(\"Initializing ctensor and loading metric from GRTensor...\");\n";
print $writeFile "load(ctensor);\n";
print $writeFile "dim:",$nDims,";\n";
print $writeFile $coordString,"\n";
print $writeFile $lgString,"\n";
for (my $i=0; $i<$#dependsArr+1; $i++) {
	print $writeFile $dependsString . $dependsArr[$i] . "\n";
}
print $writeFile "disp(lg);\ncmetric();\n";
close $writeFile;
