package TagOverride;
use strict;
use warnings;

sub _hdlr_tag_override {
    my ($ctx, $args) = @_;
    my $name = $args->{name};
    my $super = $ctx->handler_for(lc $name)
        or return $ctx->error("Cannot override for unexisting tag $name");
    my $tokens = $ctx->stash('tokens');
    my $runner = sub {
        my ( $local_ctx, $local_args, $local_cond ) = @_;
        my $hdlr = $local_ctx->stash('__handler');
        local $local_ctx->{__stash}{tag} = lc $name;
        local $local_ctx->{__stash}{__installed_tag} = lc $name;
        local $local_ctx->{__stash}{__installed_handler} = $hdlr;
        # keep $tokens into this closure.
        local $local_ctx->{__stash}{orig_tokens} = $local_ctx->{__stash}{tokens};
        local $local_ctx->{__stash}{tokens} = $tokens;
        # export args to vars
        local $local_ctx->{__stash}{vars}{args} = $local_args;
        # overrided contents
        local $local_ctx->{__stash}{__overrided_contents} = undef;
        return $local_ctx->slurp($local_args, $local_cond);
    };
    my $super_clone = MT::Template::Handler->new( $super->values );
    $super->code( $runner );
    $super->super( $super_clone );
    return '';
}

sub _hdlr_super_tag {
    my ( $ctx, $args, $cond ) = @_;
    my $hdlr = $ctx->stash('__installed_handler')
        or return $ctx->error('Cannot use mt:SuperTag outside of TagOverride block');
    my $tag = $ctx->stash('__installed_tag');
    ## import args from var
    my $orig_args = $ctx->var('args');
    my %orig_vars;
    for my $k ( keys %$orig_args ) {
        $orig_vars{$k} = $args->{$k};
        $args->{$k} = $orig_args->{$k};
    }
    local $ctx->{__stash}{tokens} = $ctx->{__stash}{orig_tokens};
    my $overrided = $ctx->stash('__overrided_contents');
    my $res;
    {
        local $ctx->{__stash}{tokens} = $overrided || $ctx->{__stash}{orig_tokens};
        local $ctx->{__stash}{__installed_handler} = $hdlr->super;
        local $ctx->{__stash}{tag} = $tag;
        $res = $hdlr->invoke_super($ctx, $args, $cond)
            or return $ctx->error('Failed to invoke super handler: ' . $ctx->errstr);
    }
    for my $k ( keys %orig_vars ) {
        $args->{$k} = $orig_vars{$k};
    }
    $res;
}

sub _hdlr_contents_override {
    my ($ctx, $args, $cond) = @_;
    my $hdlr = $ctx->stash('__installed_handler')
        or return $ctx->error('Cannot use mt:ContentsOverride outside of TagOverride block');
    $ctx->stash('__overrided_contents', $ctx->stash('tokens'));
    return '';
}

sub _hdlr_super_contents {
    my ($ctx, $args, $cond) = @_;
    local $ctx->{__stash}{tokens} = $ctx->{__stash}{orig_tokens};
    return $ctx->slurp($args, $cond);
}
1;
