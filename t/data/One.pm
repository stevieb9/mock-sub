package One;

sub new {
    return bless {}, shift;
}

sub foo {
    print "in One::foo\n";
}
sub bar {
    print "in One::bar\n";
}
sub baz {
    print "in One::baz\n";
}
1;
