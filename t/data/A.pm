package A;

sub new {
    return bless {}, shift;
}

sub foo {
    print "in A::foo\n";
}
sub bar {
    print "in A::bar\n";
}
sub baz {
    print "in A::baz\n";
}
1;
