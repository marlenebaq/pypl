#!/usr/bin/perl -w

# Marlene Baquiran
# z5061800
# http://cgi.cse.unsw.edu.au/~cs2041/assignments/plpy/

while ($line = <>) {
    if ($line =~ /^#!/ && $. == 1) {
        # print "Translating interpreter line:\n";
        # translate #! line

        print "#!/usr/local/bin/python3.5 -u\n";
    } elsif ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
        # print "Translating comment or blank line:\n";
        # Blank & comment lines can be passed unchanged

        print $line;

    # print "hello world\n";
    } elsif ($line =~ /^\s*print\s*"([^\$]*)\\n"[\s;]*$/) {
        # \s means whitespace:
        #       print     "blah blah blah\n"     ;
        # Python's print adds a new-line character by default
        # so we need to delete it from the Perl print statement

        print "print(\"$1\")\n";

    # print "$var\n";
    } elsif ($line =~ /^\s*print\s*"\$([A-Za-z0-9]+)\\n"[\s;]*$/) { # shitty
       # hack
        $replace = "print($1)";
        $line =~ s/print.*/$replace/;
        print $line;

    # print $var, "\n";
    } elsif ($line =~ /^\s*print\s*[^"]([^,]*)[^"],\s"\\n"[\s;]*$/) { # shitty
       # hack
        print "print($1)\n";
        ## do the same thing here later..g

    # a = num;
    } elsif ($line =~ /^\s*\$([A-Za-z0-9]+)\s*=\s(.*);$/) {
        $line =~ s/\$//g;
        $line =~ s/;//g;
        print $line;
    # if (a > 3) {
    } elsif ($line =~ /^\s*(if|for|while)\s\((.*)\)\s{/) {
        ## $line =~ s{(.*)\)}{$1}xms; meaning?
        # allow for grouping conditions
        $line =~ s/\(//;
        $line =~ s{(.*) \)}{$1};

        # replace brackets
        $line =~ s/\s{/:/g;

        # remove $ from vars
        $line =~ s/\$//g;

        # logical operators
        $line =~ s/&&/and/g;
        $line =~ s/\|\|/or/g;
        $line =~ s/!/not /g;
        print $line;

    # }
    } elsif ($line =~ /}/) {
    } else {
        # Lines we can't translate are turned into comments
        # print "No match for:\n";
        print "#-->$line\n";
    }
}