#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use XML::LibXML;
use XML::LibXML::XPathContext;
use List::MoreUtils qw(natatime);
use Search::ElasticSearch;
use Perl6::Say;

my $filename = shift @ARGV;

my $doc = XML::LibXML->load_xml(location => $filename);
my $xpc = XML::LibXML::XPathContext->new($doc);

$xpc->registerNs('wiki', 'http://www.mediawiki.org/xml/export-0.10/');

my $es = Search::Elasticsearch->new(
    nodes => [qw(localhost:9200)],
);
my $bulk_helper = $es->bulk_helper(
    index => 'wikipedia',
    type  => 'page',
);

my $count;
for my $page ($xpc->findnodes('/wiki:mediawiki/wiki:page')) {
    my $id = $xpc->findvalue('./wiki:id', $page);
    my $title = $xpc->findvalue('./wiki:title', $page);
    my $text = $xpc->findvalue('./wiki:revision/wiki:text', $page);

    $bulk_helper->create({
        id => $id,
        source => {
            id    => $id,
            title => $title,
            text  => $text,
        },
    });

    $count++;

    if (($count % 100) == 0) {
        say "$count indexed";
    }
}

$bulk_helper->flush;
