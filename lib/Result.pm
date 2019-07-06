package Result {
  use parent 'Exporter';

  use strictures 2;
  
  use Scalar::Util;
  use Try::Tiny;

  our @EXPORT = qw/ Ok Err /;
  our @EXPORT_OK = qw/ try_result /;

  sub Ok  { Result::Ok->new($_[0]) }
  sub Err { Result::Err->new($_[0]) }

  sub try_result :prototype(&) {
    my ($code) = @_;
    try {
      my $res = $code->(); 
      return $res if Scalar::Util::blessed($res) && $res->ISA('Result::Base');
      Ok($res);
    }
    catch {
      Err($_)
    };
  }
}

package Result::Base {
  BEGIN { $INC{'Result/Base.pm'} = __FILE__ }

  use strictures 2;

  use Carp ();

  sub new { bless \\($_[1]), $_[0] }

  # FINISHME: Do I want some way to require a result to be checked / defused
  # otherwise it cries at destruction?  could i make that testing-only like
  # strictures?

  use overload
    'nomethod' => sub {
      Carp::croak sprintf 'Used `%s` operator on a wrapped `Result` value',
        $_[3];
    },
    '""' => sub {
      # Data::Printer always tries to stringify once to check for GLOB refs,
      # without this workaround we'd never be dumpable through it
      return 'workaround' if caller eq 'Data::Printer';

      Carp::croak 'Used `""` operator on a wrapped `Result` value';
    };

  sub AUTOLOAD {
    my $method = our $AUTOLOAD =~ s/^.*:://r;
    return if $method eq 'DESTROY';

    Carp::croak sprintf 'Called `%s` on a wrapped `Result` value',
      $method;
  }
}

package Result::Ok {
  BEGIN { $INC{'Result/Ok.pm'} = __FILE__ }

  use parent 'Result::Base';

  use strictures 2;

  sub is_ok  { !!1 }
  sub is_err { !!0 }

  sub expect     { $${$_[0]} }
  sub expect_err { Carp::croak($_[1] . ': ' . $${$_[0]}) }

  sub unwrap     { $${$_[0]} }
  sub unwrap_err { $_[0]->expect_err('Called `unwrap_err` on an `Ok` value') }

  sub unwrap_or      { $${$_[0]} }
  sub unwrap_or_else { $${$_[0]} }

  sub map     { Result::Ok($_[1]->($${$_[0]})); }
  sub map_err { $_[0] }

  sub map_or_else { $_[2]->($${$_[0]}) }

  sub and { $_[1] }
  sub or  { $_[0] }

  sub and_then { $_[1]->($${$_[0]}) }
  sub or_else  { $_[0] }
}

package Result::Err {
  BEGIN { $INC{'Result/Err.pm'} = __FILE__ }

  use parent 'Result::Base';

  use strictures 2;

  sub is_err { !!1 }
  sub is_ok  { !!0 }

  sub expect_err { $${$_[0]} }
  sub expect     { Carp::croak($_[1] . ': ' . $${$_[0]}) }

  sub unwrap_err { $${$_[0]} }
  sub unwrap     { $_[0]->expect('Called `unwrap` on an `Err` value') }

  sub unwrap_or      { $_[1] }
  sub unwrap_or_else { $_[1]->($${$_[0]}) }

  sub map_err { Result::Err($_[1]->($${$_[0]})); }
  sub map     { $_[0] }

  sub map_or_else { $_[1]->($${$_[0]}) }

  sub or  { $_[1] }
  sub and { $_[0] }

  sub or_else  { $_[1]->($${$_[0]}) }
  sub and_then { $_[0] }
}

1;
__END__

=head1 NAME

Result - ripoff rust result

=head1 SYNOPSIS

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

=head1 STATUS

Not released to CPAN.

=head1 DESCRIPTION

This project is an experiment copying some of the behavior of Rust's Result
enum to Perl.  Of course you don't get some of the benefits of the type system,
but the idea is to force error handling, without throwing exceptions, while
offering chained control flow.  I decided to build it out to see how it feels
in action.

Other than C<Ok()> and C<Err()> constructors for the two result cases,
C<try_result {}> is available to catch an exception and turn it into an
C<Err($e)>.

=cut
