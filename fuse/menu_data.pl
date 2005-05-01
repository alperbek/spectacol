#!/usr/bin/perl -w

# menu_data.pl: generate the menu structure from menu_data.c
# Copyright (c) 2004 Philip Kendall

# $Id$

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 49 Temple Place, Suite 330, Boston, MA 02111-1307 USA

# Author contact information:

# Philip Kendall <pak21-fuse@srcf.ucam.org>
# Postal address: 15 Crescent Road, Wokingham, Berks, RG40 2DB, England

use strict;

use lib '../perl';
use lib '../../perl';

use Fuse;

sub get_branch ($$);
sub cname ($);
sub dump_widget ($);
sub _dump_widget ($$);
sub dump_gtk ($);
sub _dump_gtk ($$$);

die "usage: $0 <ui>" unless @ARGV >= 1;

print Fuse::GPL( 'menu_data.c: menu structure for Fuse',
		 '2004 Philip Kendall' ) . << "CODE";

/* This file is autogenerated from menu_data.c by $0.
   Any changes made here will not be preserved. */

#include <config.h>

#include "menu.h"

CODE

my $ui = shift;

my %menus = ( name => 'Main menu', submenu => [ ] );

while(<>) {

    s/#.*//;
    next if /^\s*$/;

    chomp;

    my( $path, $type, $hotkey, $function, $action ) = split /\s*,\s*/;

    my @segments = split '/', $path;

    my $entry = { };

    $entry->{name} = pop @segments;
    $entry->{type} = $type;
    $entry->{hotkey} = $hotkey if $hotkey;

    my $walk = $menus{submenu};
    $walk = get_branch( $walk, $_ ) foreach @segments;

    if( $type eq 'Branch' ) {

	$entry->{submenu} = [ ];

    } elsif( $type eq 'Item' ) {

	$entry->{function} = $function if $function;
	$entry->{action} = $action if $action;

    }

    push @$walk, $entry;

}

if( $ui eq 'gtk' ) {
    dump_gtk( \%menus );
} else {
    dump_widget( \%menus );
}

sub get_branch ($$) {

    my( $menus, $branch ) = @_;

    foreach my $entry ( @$menus ) {

	next unless $entry->{submenu};

	my $name = $entry->{name};
	$name =~ s/_//;

	return $entry->{submenu} if $name eq $branch;
    }
}

sub cname ($) {

    my( $name ) = @_;

    my $cname = lc $name;
    $cname =~ s/\\01[12]//g if $ui eq 'widget';
    $cname =~ tr/a-z0-9_//cd;

    return $cname;
}

sub dump_widget ($) {

    my( $menu ) = @_;

    print << "HEADERS";
#include "input.h"
#include "options.h"
#include "widget_internals.h"

HEADERS

    _dump_widget( $menu, 'menu' );

}

sub _dump_widget ($$) {

    my( $menu, $path ) = @_;

    my $menu_name = $menu->{name};
    $menu_name =~ s/_//;

    my $s;

    if( $path eq 'menu' ) {
	$s = 'widget_menu_entry widget_menu[]';
    } else {
    	# Slight ugliness here is because "${path}[]" doesn't work under
	# Perl 5.6
	$s = "static widget_menu_entry $path" . "[]";
    }

    $s .= " = {\n  { \"$menu_name\" },\n";

    foreach my $item ( @{ $menu->{submenu} } ) {

	next if $item->{type} eq 'Separator';

	my $name = $item->{name};
	my $key;
	if( $ui eq 'widget' ) {
	    $name =~ s/_(.)/\\012$1\\011/;
	    $key = lc $1 if $1;
	} else {
	    $name =~ s/_(.)/($1)/;
	    $key = lc $1 if $1;
	}
	
	$s .= "  { \"$name\", INPUT_KEY_" . ( $key || 'NONE' ) . ', ';

	my $cname = cname( $name );
	
	if( $item->{submenu} ) {
	    $s .= "${path}_$cname, NULL, 0";
	    _dump_widget( $item, "${path}_$cname" );
	} else {
	    my $function = $item->{function} || "${path}_$cname";
	    $s .= "NULL, $function, " . ( $item->{action} || 0 );
	}

	$s .= " },\n";
    }

    $s .= "  { NULL }\n};\n\n";

    print $s;
}

sub dump_gtk ($) {

    my( $menu ) = @_;

    print << "HEADERS";
#include <gtk/gtk.h>

HEADERS

    print "GtkItemFactoryEntry gtkui_menu_data[] = {\n\n";

    _dump_gtk( $menu, '', 'menu' );

    print << "CODE";

};

guint gtkui_menu_data_size =
  sizeof( gtkui_menu_data ) / sizeof( GtkItemFactoryEntry );
CODE
  
}

sub _dump_gtk ($$$) {

    my( $menu, $gtk_path, $cpath ) = @_;

    foreach my $item ( @{ $menu->{submenu} } ) {

	my $name = $item->{name};
	$name =~ s/_// if !$gtk_path;

	print "  { \"$gtk_path/$name\", ";

	if( $item->{hotkey} ) {
	    print "\"$item->{hotkey}\"";
	} else {
	    print 'NULL';
	}

	print ", ";

	$name =~ s/_// if $gtk_path;
	my $new_cpath = "${cpath}_" . cname( $name );

	if( $item->{type} eq 'Item' ) {
	    my $function = $item->{function} || $new_cpath;
	    print $function;
	} else {
	    print 'NULL';
	}

	print ", ", $item->{action} || 0, ", \"<$item->{type}>\" },\n";

	_dump_gtk( $item, "$gtk_path/$name", $new_cpath ) if $item->{submenu};
    }
}
