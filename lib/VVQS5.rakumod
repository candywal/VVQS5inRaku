use v6.d;
unit module VVQS5;
class Value is export {
    has $.value;
}

class NumV is Value is export {}
class BoolV is Value is export {}
class StringV is Value is export {}

class ClosV is Value is export {
    has @.args;
    has $.body;
    has %.env;
}

class PrimOpV is Value is export {
    has &.op;
}

role ExprC is export {}

class NumC does ExprC is export {
    has Numeric $.n;
}

class IdC does ExprC is export {
    has Str $.s;
}

class AppC does ExprC is export {
    has ExprC $.fun;
    has ExprC @.arg;
}

class IfC does ExprC is export {
    has ExprC $.test;
    has ExprC $.then;
    has ExprC $.else;
}

class LamC does ExprC is export {
    has Str @.args;
    has ExprC $.body;
}

class StringC does ExprC is export {
    has Str $.s;
}

our %top-env is export;
%top-env{'true'} = BoolV.new(value => Bool::True);
%top-env{'false'} = BoolV.new(value => Bool::False);
%top-env{'+'} = PrimOpV.new(
        op => -> NumV $a, NumV $b {
            NumV.new(value => $a.value + $b.value)
        }
        );
%top-env{'-'} = PrimOpV.new(op => -> NumV $a, NumV $b { NumV.new(value => $a.value - $b.value) });
%top-env{'*'} = PrimOpV.new(op => -> NumV $a, NumV $b { NumV.new(value => $a.value * $b.value) });
%top-env{'/'} = PrimOpV.new(op => -> NumV $a, NumV $b { NumV.new(value => $a.value / $b.value) });
%top-env{'error'} = PrimOpV.new(op => -> StringV $a {die $a.value});
%top-env{'<='} = PrimOpV.new(op => -> NumV $a, NumV $b { BoolV.new(value => $a.value <= $b.value) });
%top-env{'equal?'} = PrimOpV.new(op => -> Value $a, Value $b {BoolV.new(b => $a.value == $b.value) });

sub lookup(Str $s, %env) is export { %env{$s} }

our sub interp(ExprC $e, %env) is export {
    given $e {
        when NumC {
            return NumV.new(value => $e.n);
        }
        when IdC {
            return lookup($e.s, %env);
        }
        when StringC {
            return StringV.new(value => $e.s);
        }
        when IfC {
            my $test-value = interp($e.test, %env);
            given $test-value {
                when BoolV {
                    return interp($test-value.value ?? $e.then !! $e.else, %env);
                }
                default {
                    die "Non-boolean test in if: {$e.test}"
                }
            }
        }
        when LamC {
            return ClosV.new(args => $e.args, body => $e.body, env => %env);
        }
        when AppC {
            my @arg-values = $e.arg.map({ interp($_, %env) });
            my $fun-value = interp($e.fun, %env);
            given $fun-value {
                when ClosV {
                    if @arg-values.elems != $fun-value.args.elems {
                        die "Wrong number of arguments for function: {$e.fun}"
                    }
                    my %clos-env = |%env;
                    for $fun-value.args.kv -> $i, $arg-sym {
                        %clos-env{$arg-sym} = @arg-values[$i];
                    }
                    return interp($fun-value.body, %clos-env);
                }
                when PrimOpV {
                    return $fun-value.op(@arg-values);
                }
                default {
                    die "Application of non-function: {$e.fun}"
                }
            }
        }
    }
}
