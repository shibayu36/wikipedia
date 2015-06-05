#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Search::ElasticSearch;
use JSON::Types qw/bool/;

my $es = Search::Elasticsearch->new(
    nodes => [qw(localhost:9200)],
);

$es->indices->create(
    index => 'wikipedia',
    body  => {
        settings => {
            index => {
                analysis => {
                    tokenizer => {
                        text_ja_tokenizer => {
                            type => 'kuromoji_tokenizer',
                            mode => 'search',
                        },
                    },
                    analyzer => {
                        text_ja_analyzer => {
                            tokenizer => 'text_ja_tokenizer',
                            type => 'custom',
                            filter => [
                                'kuromoji_part_of_speech',
                                'icu_normalizer',
                            ],
                            char_filter => [
                                'html_strip'
                            ],
                        },
                    },
                },
            },
        },
        mappings => {
            page => {
                properties => {
                    id    => +{ type => 'long', index => 'not_analyzed' },
                    title => +{ type => 'string', index => 'analyzed', analyzer => 'text_ja_analyzer' },
                    text  => +{ type => 'string', index => 'analyzed', analyzer => 'text_ja_analyzer' },
                },
            },
        },
    },
);
