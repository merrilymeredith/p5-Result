#!perl

use Test2::V0;
use strictures 2;

use Result;

can_ok 'main', qw/
  Ok
  Err
/;

subtest 'Result::Ok' => sub {
  my $ok = Ok(42);

  ok $ok->is_ok,
    'is_ok';
  ok !$ok->is_err,
    'is_err';

  is $ok->expect('...'), 42,
    'expect';
  ok dies { $ok->expect_err('...') },
    'expect_err';

  is $ok->unwrap, 42,
    'unwrap';
  ok dies { $ok->unwrap_err },
    'unwrap_err';

  is $ok->unwrap_or('...'), 42,
    'unwrap_or';
  is $ok->unwrap_or_else('...'), 42,
    'unwrap_or_else';

  is $ok->map(sub { $_[0] / 2 })->unwrap, 21,
    'map';
  is $ok->map_err(sub { $_[0] / 2 })->unwrap, 42,
    'map_err';

  is $ok->map_or_else(sub { $_[0] / 2 }, sub { $_[0] * 2 }), 84,
    'map_or_else';

  is $ok->and(Ok('wow'))->unwrap, 'wow',
    'and';
  is $ok->or(Ok('wow'))->unwrap, 42,
    'or';

  is $ok->and_then(sub { Ok(55) })->unwrap, 55,
    'and_then';
  is $ok->or_else(sub{ Ok(55) })->unwrap, 42,
    'or_else';
};

subtest 'Result::Err' => sub {
  my $err = Err('ack');

  ok $err->is_err,
    'is_err';
  ok !$err->is_ok,
    'is_ok';

  is $err->expect_err, 'ack',
    'expect_err';
  ok dies { $err->expect('...') },
    'expect';

  is $err->unwrap_err, 'ack',
    'unwrap_err';
  ok dies { $err->unwrap },
    'unwrap';

  is $err->unwrap_or('xyzzy'), 'xyzzy',
    'unwrap_or';
  is $err->unwrap_or_else(\&CORE::uc), 'ACK',
    'unwrap_or_else';

  is $err->map_err(\&CORE::uc)->unwrap_err, 'ACK',
    'map_err';
  is $err->map(\&CORE::uc)->unwrap_err, 'ack',
    'map';

  is $err->map_or_else(sub {'foo'}, sub {'baz'}), 'foo',
    'map_or_else';

  is $err->or(Ok('whoa'))->unwrap, 'whoa',
    'or';
  is $err->and(Ok('whoa'))->unwrap_err, 'ack',
    'and';

  is $err->or_else(sub { Err('yikes') })->unwrap_err, 'yikes',
    'or_else';

  is $err->and_then(sub { Err('hmm') })->unwrap_err, 'ack',
    'and_then';
};

subtest chains => sub {
  my $sq = sub { Ok($_[0] * $_[0]) };

  is
    Ok(2)->and_then(\&Err)->and_then($sq)->unwrap_err,
    2,
    'and_then chain 3';

  is
    Err(3)->or_else($sq)->or_else(\&Err)->unwrap,
    9,
    'or_else chain 3';
};

subtest 'try_result' => sub {
  use Result 'try_result';

  ok try_result { Err() }->is_err,
    'results not rewrapped';

  my $res;
  ok lives {$res = try_result { die 'what' }},
    'no exception thrown at caller';

  like $res->unwrap_err,
    qr'what',
    'caught and wrapped error';
};

done_testing;
