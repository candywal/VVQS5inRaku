use v6.d;
use Test;
use lib '.';
use VVQS5;

# Define a helper function for testing
sub test-interp(ExprC $expr, %env, Value $expected) {
    my $result = interp($expr, %env);
    is-deeply $result, $expected, $expr.gist;
}

# Test the NumC case-0-
test-interp(NumC.new(n => 42), {}, NumV.new(value => 42));

# Test the IdC case
test-interp(IdC.new(s => 'x'), {'x' => NumV.new(value => 42)}, NumV.new(value => 42));

# Test the StringC case
test-interp(StringC.new(s => 'Hello, world!'), {}, StringV.new(value => 'Hello, world!'));

# Test the IfC case
test-interp(
        IfC.new(
                test => IdC.new(s => 'x'),
                then => NumC.new(n => 42),
                else => NumC.new(n => 0)
                ),
        {'x' => BoolV.new(value => True)},
        NumV.new(value => 42)
                 );

# Test the LamC and AppC cases
# Test the LamC and AppC cases
test-interp(
        AppC.new(
                fun => LamC.new(args => ['x'], body => IdC.new(s => 'x')),
                arg => [NumC.new(n => 42)]
                ),
        {},
        NumV.new(value => 42)
                     );
test-interp(IdC.new(s => 'y'), {'x' => NumV.new(value => 42), 'y' => NumV.new(value => 47)}, NumV.new(value => 47));

test-interp(
        IfC.new(
                test => IdC.new(s => 'r'),
                then => NumC.new(n => 42),
                else => NumC.new(n => 6)
                ),
        {'r' => BoolV.new(value => False)},
        NumV.new(value => 6)
                     );
test-interp(IdC.new(s => 'true'), %top-env, BoolV.new(value => Bool::True));
test-interp(IdC.new(s => 'false'), %top-env, BoolV.new(value => Bool::False));

done-testing;
