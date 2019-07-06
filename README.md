# NAME

Result - ripoff rust result

# SYNOPSIS

    use Result qw/Ok Err try_result/;

    sub do_the_thing {
      try_result { activity_that_may_die() }
        ->and_then(\&activity_returning_result)
    }

    sub activity_that_may_die {
      die 'ack!' if rand > 0.8;
      return 17 if rand > 0.9;
      84
    }

    sub activity_returning_result {
      my ($in) = @_;
      return Ok($in / 2) if $in % 2 == 0;
      Err('Odd numbers are gross');
    }

    do_the_thing()->expect('Failed to do thing');

# STATUS

Not released to CPAN.

# DESCRIPTION

This project is an experiment copying some of the behavior of Rust's Result
enum to Perl.  Of course you don't get some of the benefits of the type system,
but the idea is to force error handling, without throwing exceptions, while
offering chained control flow.  I decided to build it out to see how it feels
in action.

Other than `Ok()` and `Err()` constructors for the two result cases,
`try_result {}` is available to catch an exception and turn it into an
`Err($e)`.
