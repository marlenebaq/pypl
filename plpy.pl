#!/usr/bin/perl -w

# Marlene Baquiran
# z5061800
# http://cgi.cse.unsw.edu.au/~cs2041/assignments/plpy/

my %imports = ();
my %lookup = (
    "<STDIN>" => "sys.stdin.readline()",

    "&&" => "and",
    "||" => "or",
    "!" => "not ",
);

# MAIN
while (my $pl_line = <>) {
    our @py_code;
    our @py_header;
    translate_pl_line($pl_line);
}
my @py_lines = join('', @py_header,@py_code);
print @py_lines;

sub translate_pl_line {
    my ($line) = @_;
    my $whitespace = ($line =~ /^(\s*)/g)[0];
    my $contents = ($line =~ /([^\s].*)/g)[0];

    if ($contents) {
        $contents = prelim_syntax_cleanup($contents);
        if ($contents =~ /^#!/ && $. == 1) {
            # translate #! line
            $contents = "";
            push @py_header, "#!/usr/local/bin/python3.5 -u\n";
        } elsif ($contents =~ /print\s*(.*)/) {
            # handle print statements
            # $1 - all content
            $contents = handle_print($1);
        } elsif ($contents =~ /^\s*(if|elsif|while)\s*\((.*)\)\s*{/) {
            # handle if and whiles
            # $1 - condition type
            # $2 - condition
            # TODO: handle else {
            $contents = handle_conditional($1, $2);
        } elsif ($contents =~ /foreach\s*\$([^\s]*)\s*\(@(.*)\)\s*{/) {
            # handle foreach
            $contents = handle_foreach($1, $2);
        } elsif ($contents =~ /\$([a-z0-9]+)((\+|-)){2}$/i) {
            # handle (in|de)crements
            # $1 - var to (in|de)crement
            # $2 - operator (+|-)
            $contents = handle_inde_crement($1, $2);
        } elsif ($contents =~ /(last|next)$/) {
            # handle last/next
            # $1 - all content
            $contents = handle_last_next($1);
        } elsif ($contents =~ /chomp\s+(.*)$/) {
            # handle chomp
            # $1 - var to chomp
            $contents = handle_chomp($1);
        } elsif ($line =~ /\$([a-z0-9]+) = <STDIN>/i) {
            # handle read from stdin
            # $1 - var to assign
            $contents = handle_read_stdin($1);
        } elsif ($contents =~ /}/) {
            # remove closing curly brace and the line it occupies
            $whitespace = "";
            $contents = "";
        } elsif ($contents =~ /^\s*#/) {
            # comments pass through unchanged
        } else {
            $contents =~ /^\s*(.*)/;
            # cleanup variable assignments
            $contents = cleanup_remaining_syntax($1);
        }
        $line = $whitespace . $contents;
    }

    push @py_code, $line;
}

# SUBROUTINES FOR LINE TYPES

sub prelim_syntax_cleanup {
    # cleanup ; (trailing), ..
    my ($contents) = @_;
    $contents =~ s{;$}{}g; # remove only trailing semicolons
    $contents =~ s{\.\.}{:}g; # Note: this will capture .. in strings
    return $contents;
}

sub handle_print {
    my ($contents) = @_;
    my $has_new_line = 0;

    # remove only trailing new lines
    # i.e. print "Hello\nWorld"; is passable
    if ($contents =~ /\\n"/) {
        $has_new_line = 1;
        $contents =~ s{,\s*"\\n"\s*$}{}g;
        $contents =~ s{\\n\s*"\s*$}{"}g;
    }

    if ($contents =~ /^([^"]*)$/ || $contents =~ /^"?\$([^\s\"]*)"?$/) {
        $contents = $1;
        $contents =~ s{\$}{}g;
    } else {
        my @components = split(' ', $contents);
        my @vars;
        foreach $component (@components) {
            if (substr($component, 0, 1) eq '$') {
                $component =~ /(\w+)/;
                $component = "%s";
                push @vars, $1;
            }
        }
        $contents = join(' ', @components);
        if (@vars) {
                my @format = join(', ', @vars);
                $contents .= "%(@format)";
        }
    }

    if ($has_new_line == 0) {
        $contents .= ", end=\"\"";
    }
    return "print($contents)\n";
}

sub handle_conditional {## $line =~ s{(.*)\)}{$1}xms; meaning?
    my ($statement_type, $condition) = @_;

    if ($statement_type eq "elsif") {
        $statement_type = "elif" ;
    }

    # remove $ from vars
    $condition =~ s{\$}{}g;
    # change eq to == (value test, not identity)
    $condition =~ s{eq}{==}g;
    # logical operators
    $condition =~ s{&&}{and}g;
    $condition =~ s{\|\|}{or}g;
    $condition =~ s{!}{not }g;

    return "$statement_type " . $condition . ":\n";
}

sub handle_foreach {
    my ($iterator, $iterable) = @_;
    return "for $iterator in $iterable:\n";
}

sub handle_inde_crement {
    my ($var, $operator) = @_;
    return "$var $operator= 1\n";
}

sub handle_last_next {
    my ($contents) = @_;
    $contents =~ s{last}{break};
    $contents =~ s{next}{continue};
    return "$contents\n";
}

sub handle_chomp {
    my ($var) = @_;
    # TODO: need to check if $1 is empty or not to handle $_ ...
    $var =~ s{[\$;]}{}g;
    return "$var = $var.rstrip()\n";
}

sub handle_read_stdin {
    my ($var) = @_;
    # TODO: make sure this only imports once
    push @py_header, "import sys\n";
    return "$var = $lookup{\"<STDIN>\"}\n";
}

sub cleanup_remaining_syntax {
    my ($contents) = @_;
    $contents =~ s{[\$@%;]}{}g;
    return "$contents\n";
}