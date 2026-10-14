#!/usr/bin/perl
# convert_nod.pl - convert an original Half-Life binary node graph (.nod,
# GRAPH_VERSION 16) into Libre-life's LL_NODEGRAPH text format, which the
# QC loader (serverqc/ai/nodegraph.qc :: NodeGraph_Load) reads directly.
#
#   perl convert_nod.pl <input.nod> > <output.nod>
#
# Verified struct layout (32-bit MSVC, 4-byte alignment):
#   file = [int version=16][CGraph 8396][CNode 88 * cNodes]
#          [CLink 24 * cLinks][DIST_INFO 16 * cNodes][routeinfo][hashlinks]
#   CGraph: m_cNodes@24  m_cLinks@28
#   CNode : m_vecOrigin@0(3f)  m_afNodeInfo@28  m_cNumLinks@32
#           m_iFirstLink@36  m_sHintType@80(s)  m_sHintActivity@82(s)
#           m_flHintYaw@84(f)
#   CLink : m_iDestNode@4  m_szLinkEntModelname@12(4)  m_afLinkInfo@16
#           m_flWeight@20(f)
# HL bits_NODE_* (LAND=1,AIR=2,WATER=4) and bits_LINK_* (SMALL=1,HUMAN=2,
# LARGE=4,FLY=8) match Libre-life's NODE_REALM_* / LINK_* exactly.

use strict;
use warnings;

my $CGRAPH = 8396;
my $CNODE  = 88;
my $CLINK  = 24;

my $path = $ARGV[0] or die "usage: convert_nod.pl <input.nod>\n";
open(my $fh, '<:raw', $path) or die "open $path: $!\n";
local $/;
my $buf = <$fh>;
close $fh;

my $ver = unpack('l', substr($buf, 0, 4));
die "$path: version $ver, expected 16\n" unless $ver == 16;

my $cNodes = unpack('l', substr($buf, 4 + 24, 4));
my $cLinks = unpack('l', substr($buf, 4 + 28, 4));
die "$path: insane counts ($cNodes,$cLinks)\n"
    if $cNodes < 0 || $cNodes > 8192 || $cLinks < 0 || $cLinks > 200000;

my $nodeBase = 4 + $CGRAPH;
my $linkBase = $nodeBase + $cNodes * $CNODE;

print "LL_NODEGRAPH 3 $cNodes $cLinks 0\n";

for (my $i = 0; $i < $cNodes; $i++) {
    my $o = $nodeBase + $i * $CNODE;
    my ($x, $y, $z) = unpack('f3', substr($buf, $o, 12));
    my $info     = unpack('l', substr($buf, $o + 28, 4));
    my $numlinks = unpack('l', substr($buf, $o + 32, 4));
    my $first    = unpack('l', substr($buf, $o + 36, 4));
    my $hint     = unpack('s', substr($buf, $o + 80, 2));
    my $hintact  = unpack('s', substr($buf, $o + 82, 2));
    my $hintyaw  = unpack('f', substr($buf, $o + 84, 4));
    my $realm    = $info & 7;
    $realm = 1 if $realm == 0;   # default to LAND
    printf "N %.4f %.4f %.4f %d %d %d %.4f %d %d\n",
        $x, $y, $z, $realm, $hint, $hintact, $hintyaw, $first, $numlinks;
}

for (my $i = 0; $i < $cLinks; $i++) {
    my $o = $linkBase + $i * $CLINK;
    my $dest   = unpack('l', substr($buf, $o + 4, 4));
    my $model  = substr($buf, $o + 12, 4);
    my $afinfo = unpack('l', substr($buf, $o + 16, 4));
    my $weight = unpack('f', substr($buf, $o + 20, 4));
    my $bits   = $afinfo & 15;
    # A non-empty link-ent model name means a brush model (usually a door)
    # blocks this link -> mark it door-gated. "-" = open link.
    my $door = "-";
    if (length($model) && ord(substr($model, 0, 1)) != 0) {
        ($door = $model) =~ s/[^\x20-\x7e]//g;
        $door = "door" if $door eq "" || $door =~ /\s/;
    }
    printf "L %d %d %.4f %s\n", $dest, $bits, $weight, $door;
}
