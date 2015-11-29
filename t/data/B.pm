package B;

use lib '.';
use A;

sub test {
    my $obj = A->new;
    $obj->foo;
}
sub test2 {
    my $obj = A->new;
    $obj->bar;
}
sub test3 {
    my $obj = A->new;
    $obj->baz;
}

1;
