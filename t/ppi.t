use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Differences;

use_ok("Parse::Method::Signatures") or BAIL_OUT("$@");

is( Parse::Method::Signatures->new("ArrayRef")->_ident(), "ArrayRef");
is( Parse::Method::Signatures->new("where::Foo")->_ident(), "where::Foo");

{ local $TODO = "sort out lextable";
is( Parse::Method::Signatures->new("where Foo")->_ident(), undef);
}

throws_ok {
  Parse::Method::Signatures->new("Foo[Bar")->tc()
} qr/^\QRunaway '[]' in type constraint near '[Bar' at\E/;

throws_ok {
  Parse::Method::Signatures->new("Foo[Bar:]")->tc()
} qr/^\QError parsing type constraint near 'Bar:' in 'Bar:' at\E/;

is( Parse::Method::Signatures->new("ArrayRef")->tc(), "ArrayRef");
is( Parse::Method::Signatures->new("ArrayRef[Str => Str]")->tc(), "ArrayRef[Str => Str]");
is( Parse::Method::Signatures->new("ArrayRef[Str]")->tc(), "ArrayRef[Str]");
is( Parse::Method::Signatures->new("ArrayRef[0 => Foo]")->tc(), "ArrayRef[0 => Foo]");
is( Parse::Method::Signatures->new("ArrayRef[qq/0/]")->tc(), "ArrayRef[qq/0/]");

lives_ok { Parse::Method::Signatures->new('$x')->param() };

throws_ok {
  Parse::Method::Signatures->new('$x[0]')->param()
  } qr/Error parsing parameter near '\$x' in '\$x\[0\]' at /;

test_param(
  Parse::Method::Signatures->new('$x')->param(),
  { required => 0,
    sigil => '$',
    variable_name => '$x',
    __does => ["Parse::Method::Signatures::Param::Positional"],
  }
);

test_param(
  Parse::Method::Signatures->new('@x')->param(),
  { required => 0,
    sigil => '@',
    variable_name => '@x',
    __does => ["Parse::Method::Signatures::Param::Positional"],
  }
);

test_param(
  Parse::Method::Signatures->new(':$x')->param(),
  { required => 1,
    sigil => '$',
    variable_name => '$x',
    __does => ["Parse::Method::Signatures::Param::Named"],
  }
);


sub test_param {
  my ($param, $wanted, $msg) = @_;
  local $Test::Builder::Level = 2;

  use Data::Dump qw/pp/;
  if (my $isa = delete $wanted->{__isa}) {
    isa_ok($param, $isa, $msg)
      or diag(pp $param->meta->linearized_isa);
  }

  for ( @{ delete $wanted->{__does} || [] }) {
    ok(0 , "Param doesn't do $_" ) && last
      unless $param->does($_)
  }

  my $p = { %$param };
  delete $p->{_trait_namespace};
  eq_or_diff($p, $wanted, $msg);
}
