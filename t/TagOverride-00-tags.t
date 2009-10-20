use strict;
use warnings;
use lib qw( lib extlib ../lib ../extlib t/lib t/extlib );
use MT::Test qw(:db :data);
use Test::More;
use MT;
use MT::Builder;
use MT::Util::YAML;
my $mt    = MT->new;
my $build = MT::Builder->new;
my $ctx   = MT::Template::Context->new;
$ctx->stash(blog_id => 1);
$ctx->stash(blog => MT->model('blog')->load(1));

sub test {
    my ($tmpl, $expect, $desc) = @_;
    my $tokens = $build->compile($ctx, $tmpl);
    my $result = $build->build($ctx, $tokens);
    is( $result, $expect, $desc ); 
}

my $data;
{
    local $/;
    $data = <DATA>;
}
my $test_suite = MT::Util::YAML::Load($data);
$test_suite = $test_suite->{tests};
plan tests => ( scalar @$test_suite );
my $i = 0;
for my $test ( @$test_suite ) {
    test( $test->{tmpl}, $test->{expect}, $test->{description} || "Template " . $i++ );
}

__END__
tests:
    -
        description: install
        tmpl: '<mt:tagOverride name="entryTitle">foo<mt:superTag>bar</mt:tagOverride>'
        expect: ''
    -
        tmpl: '<mt:entries id="1"><mt:entryTitle></mt:entries>'
        expect: fooA Rainy Daybar
    -
        tmpl: '<mt:tagOverride name="entryTitle">fizz<mt:superTag>buzz</mt:tagOverride>'
        expect: ''
        description: one more override
    -
        tmpl: '<mt:entries id="1"><mt:entryTitle></mt:entries>'
        expect: 'fizzfooA Rainy Daybarbuzz'
    -
        tmpl: '<mt:tagOverride name="entries"><mt:contentsOverride>*<mt:superContents>*</mt:contentsOverride><mt:superTag></mt:tagOverride>'
        expect: ''
    -
        tmpl: '<mt:entries id="1"><mt:entryTitle></mt:entries>'
        expect: '*fizzfooA Rainy Daybarbuzz*'

