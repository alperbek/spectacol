#!/usr/bin/perl -w

# settings.pl: generate settings.c from settings.dat
# Copyright (c) 2002-2005 Philip Kendall

# $Id$

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Author contact information:

# E-mail: philip-fuse@shadowmagic.org.uk

use strict;

use Fuse;

sub hashline ($) { '#line ', $_[0] + 1, '"', __FILE__, "\"\n" }

my %options;

while(<>) {

    next if /^\s*$/;
    next if /^\s*#/;

    chomp;

    my( $name, $type, $default, $short, $commandline, $configfile ) =
	split /\s*,\s*/;

    if( not defined $commandline ) {
	$commandline = $name;
	$commandline =~ s/_/-/g;
    }

    if( not defined $configfile ) {
	$configfile = $commandline;
	$configfile =~ s/-//g;
    }

    $options{$name} = { type => $type, default => $default, short => $short,
			commandline => $commandline,
			configfile => $configfile };
}

print Fuse::GPL( 'settings.c: Handling configuration settings',
		 'Copyright (c) 2002 Philip Kendall' );

print hashline( __LINE__ ), << 'CODE';

/* This file is autogenerated from settings.dat by settings.pl.
   Do not edit unless you know what will happen! */

#include <config.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#ifdef HAVE_GETOPT_LONG		/* Did our libc include getopt_long? */
#include <getopt.h>
#elif defined AMIGA || defined __MORPHOS__            /* #ifdef HAVE_GETOPT_LONG */
/* The platform uses GNU getopt, but not getopt_long, so we get
   symbol clashes on this platform. Just use getopt */
#else				/* #ifdef HAVE_GETOPT_LONG */
#include "compat.h"		/* If not, use ours */
#endif				/* #ifdef HAVE_GETOPT_LONG */

#ifdef HAVE_LIB_XML2
#include <libxml/xmlmemory.h>
#include <libxml/parser.h>
#endif				/* #ifdef HAVE_LIB_XML2 */

#include "fuse.h"
#include "machine.h"
#include "settings.h"
#include "spectrum.h"
#include "ui/ui.h"
#include "utils.h"

/* The name of our configuration file */
#ifdef WIN32
#define CONFIG_FILE_NAME "fuse.cfg"
#else				/* #ifdef WIN32 */
#define CONFIG_FILE_NAME ".fuserc"
#endif				/* #ifdef WIN32 */

/* The current settings of options, etc */
settings_info settings_current;

/* The default settings of options, etc */
settings_info settings_default = {
CODE

    foreach my $name ( sort keys %options ) {
	next if $options{$name}->{type} eq 'null';
	print "  /* $name */ $options{$name}->{default},\n";
    }

print hashline( __LINE__ ), << 'CODE';
  /* show_help */ 0,
  /* show_version */ 0,
};

#ifdef HAVE_LIB_XML2
static int read_config_file( settings_info *settings );
static int parse_xml( xmlDocPtr doc, settings_info *settings );
#endif				/* #ifdef HAVE_LIB_XML2 */

static int settings_command_line( settings_info *settings, int *first_arg,
				  int argc, char **argv );

static int settings_copy_internal( settings_info *dest, settings_info *src );

/* Called on emulator startup */
int
settings_init( int *first_arg, int argc, char **argv )
{
  int error;

  error = settings_defaults( &settings_current );
  if( error ) {
    ui_error( UI_ERROR_ERROR, "out of memory at %s:%d", __FILE__, __LINE__ );
    return error;
  }

#ifdef HAVE_LIB_XML2
  error = read_config_file( &settings_current );
  if( error ) return error;
#endif				/* #ifdef HAVE_LIB_XML2 */

  error = settings_command_line( &settings_current, first_arg, argc, argv );
  if( error ) return error;

  return 0;
}

/* Fill the settings structure with sensible defaults */
int settings_defaults( settings_info *settings )
{
  return settings_copy_internal( settings, &settings_default );
}

#ifdef HAVE_LIB_XML2

/* Read options from the config file (if libxml2 is available) */

static int
read_config_file( settings_info *settings )
{
  const char *home; char path[256];
  struct stat stat_info;

  xmlDocPtr doc;

  home = compat_get_home_path(); if( !home ) return 1;

  snprintf( path, 256, "%s/%s", home, CONFIG_FILE_NAME );

  /* See if the file exists; if doesn't, it's not a problem */
  if( stat( path, &stat_info ) ) {
    if( errno == ENOENT ) {
      return 0;
    } else {
      ui_error( UI_ERROR_ERROR, "couldn't stat '%s': %s", path,
		strerror( errno ) );
      return 1;
    }
  }

  doc = xmlParseFile( path );
  if( !doc ) {
    ui_error( UI_ERROR_ERROR, "error reading config file" );
    return 1;
  }

  if( parse_xml( doc, settings ) ) { xmlFreeDoc( doc ); return 1; }

  xmlFreeDoc( doc );

  return 0;
}

static int
parse_xml( xmlDocPtr doc, settings_info *settings )
{
  xmlNodePtr node;
  xmlChar *xmlstring;

  node = xmlDocGetRootElement( doc );
  if( xmlStrcmp( node->name, (const xmlChar*)"settings" ) ) {
    ui_error( UI_ERROR_ERROR, "config file's root node is not 'settings'" );
    return 1;
  }

  node = node->xmlChildrenNode;
  while( node ) {

CODE

foreach my $name ( sort keys %options ) {

    my $type = $options{$name}->{type};

    if( $type eq 'boolean' or $type eq 'numeric' ) {

	print << "CODE";
    if( !strcmp( (const char*)node->name, "$options{$name}->{configfile}" ) ) {
      xmlstring = xmlNodeListGetString( doc, node->xmlChildrenNode, 1 );
      settings->$name = atoi( (char*)xmlstring );
      xmlFree( xmlstring );
    } else
CODE

    } elsif( $type eq 'string' ) {

	    print << "CODE";
    if( !strcmp( (const char*)node->name, "$options{$name}->{configfile}" ) ) {
      xmlstring = xmlNodeListGetString( doc, node->xmlChildrenNode, 1 );
      free( settings->$name );
      settings->$name = strdup( (char*)xmlstring );
      xmlFree( xmlstring );
    } else
CODE

    } elsif( $type eq 'null' ) {

	    print << "CODE";
    if( !strcmp( (const char*)node->name, "$options{$name}->{configfile}" ) ) {
      /* Do nothing */
    } else
CODE

    } else {
	die "Unknown setting type `$type'";
    }
}

print hashline( __LINE__ ), << 'CODE';
    if( !strcmp( (const char*)node->name, "text" ) ) {
      /* Do nothing */
    } else {
      ui_error( UI_ERROR_WARNING, "Unknown setting '%s' in config file",
		node->name );
    }

    node = node->next;
  }

  return 0;
}

int
settings_write_config( settings_info *settings )
{
  const char *home; char path[256], buffer[80]; 

  xmlDocPtr doc; xmlNodePtr root;

  home = compat_get_home_path(); if( !home ) return 1;

  snprintf( path, 256, "%s/%s", home, CONFIG_FILE_NAME );

  /* Create the XML document */
  doc = xmlNewDoc( (const xmlChar*)"1.0" );

  root = xmlNewNode( NULL, (const xmlChar*)"settings" );
  xmlDocSetRootElement( doc, root );
CODE

foreach my $name ( sort keys %options ) {

    my $type = $options{$name}->{type};

    if( $type eq 'boolean' ) {

	print "  xmlNewTextChild( root, NULL, (const xmlChar*)\"$options{$name}->{configfile}\", (const xmlChar*)(settings->$name ? \"1\" : \"0\") );\n";

    } elsif( $type eq 'string' ) {
	print << "CODE";
  if( settings->$name )
    xmlNewTextChild( root, NULL, (const xmlChar*)"$options{$name}->{configfile}", (const xmlChar*)settings->$name );
CODE
    } elsif( $type eq 'numeric' ) {
	print << "CODE";
  if( settings->$name ) {
    snprintf( buffer, 80, "%d", settings->$name );
    xmlNewTextChild( root, NULL, (const xmlChar*)"$options{$name}->{configfile}", (const xmlChar*)buffer );
  }
CODE
    } elsif( $type eq 'null' ) {
	# Do nothing
    } else {
	die "Unknown setting type `$type'";
    }
}

  print hashline( __LINE__ ), << 'CODE';

  xmlSaveFormatFile( path, doc, 1 );

  return 0;
}

#endif				/* #ifdef HAVE_LIB_XML2 */

/* Read options from the command line */
static int
settings_command_line( settings_info *settings, int *first_arg,
                       int argc, char **argv )
{

#if !defined AMIGA && !defined __MORPHOS__

  struct option long_options[] = {

CODE

my $fake_short_option = 256;

foreach my $name ( sort keys %options ) {

    my $type = $options{$name}->{type};
    my $commandline = $options{$name}->{commandline};
    my $short = $options{$name}->{short};

    unless( $type eq 'boolean' or $short ) { $short = $fake_short_option++ }

    if( $type eq 'boolean' ) {

	print << "CODE";
    {    "$commandline", 0, &(settings->$name), 1 },
    { "no-$commandline", 0, &(settings->$name), 0 },
CODE
    } elsif( $type eq 'string' or $type eq 'numeric' ) {

	print "    { \"$commandline\", 1, NULL, $short },\n";
    } elsif( $type eq 'null' ) {
	# Do nothing
    } else {
	die "Unknown setting type `$type'";
    }
}

print hashline( __LINE__ ), << 'CODE';

    { "help", 0, NULL, 'h' },
    { "version", 0, NULL, 'V' },

    { 0, 0, 0, 0 }		/* End marker: DO NOT REMOVE */
  };

#endif      /* #ifndef AMIGA */

  while( 1 ) {

    int c;

#if defined AMIGA || defined __MORPHOS__
    c = getopt( argc, argv, "d:hm:o:p:f:r:s:t:v:g:j:V" );
#else                    /* #ifdef AMIGA */
    c = getopt_long( argc, argv, "d:hm:o:p:f:r:s:t:v:g:j:V", long_options, NULL );
#endif                   /* #ifdef AMIGA */

    if( c == -1 ) break;	/* End of option list */

    switch( c ) {

    case 0: break;	/* Used for long option returns */

CODE

$fake_short_option = 256;

foreach my $name ( sort keys %options ) {

    my $type = $options{$name}->{type};
    my $short = $options{$name}->{short};

    unless( $type eq 'boolean' or $short ) { $short = $fake_short_option++ }

    if( $type eq 'boolean' ) {
	# Do nothing
    } elsif( $type eq 'string' ) {
	print "    case $short: settings_set_string( &settings->$name, optarg ); break;\n";
    } elsif( $type eq 'numeric' ) {
	print "    case $short: settings->$name = atoi( optarg ); break;\n";
    } elsif( $type eq 'null' ) {
	# Do nothing
    } else {
	die "Unknown setting type `$type'";
    }
}

print hashline( __LINE__ ), << 'CODE';

    case 'h': settings->show_help = 1; break;
    case 'V': settings->show_version = 1; break;

    case ':':
    case '?':
      break;

    default:
      fprintf( stderr, "%s: getopt_long returned `%c'\n",
	       fuse_progname, (char)c );
      break;

    }
  }

  /* Store the location of the first non-option argument */
  *first_arg = optind;

  return 0;
}

/* Copy one settings object to another */
static int
settings_copy_internal( settings_info *dest, settings_info *src )
{
  if( dest->start_machine ) {
    free( dest->start_machine );
    dest->start_machine = NULL;
  }
  if( dest->start_scaler_mode ) {
    free( dest->start_scaler_mode );
    dest->start_scaler_mode = NULL;
  }

CODE

foreach my $name ( sort keys %options ) {

    my $type = $options{$name}->{type};

    if( $type eq 'boolean' or $type eq 'numeric' ) {
	print "  dest->$name = src->$name;\n";
    } elsif( $type eq 'string' ) {
	print << "CODE";
  dest->$name = NULL;
  if( src->$name ) {
    dest->$name = strdup( src->$name );
    if( !dest->$name ) { settings_free( dest ); return 1; }
  }
CODE
    }
}

print hashline( __LINE__ ), << 'CODE';

  return 0;
}

/* Copy one settings object to another */
int settings_copy( settings_info *dest, settings_info *src )
{
  if( settings_defaults( dest ) ) return 1;
  return settings_copy_internal( dest, src );
}

char **
settings_get_rom_setting( settings_info *settings, size_t which )
{
  switch( which ) {
  case  0: return &( settings->rom_16       );
  case  1: return &( settings->rom_48       );
  case  2: return &( settings->rom_128_0    );
  case  3: return &( settings->rom_128_1    );
  case  4: return &( settings->rom_plus2_0  );
  case  5: return &( settings->rom_plus2_1  );
  case  6: return &( settings->rom_plus2a_0 );
  case  7: return &( settings->rom_plus2a_1 );
  case  8: return &( settings->rom_plus2a_2 );
  case  9: return &( settings->rom_plus2a_3 );
  case 10: return &( settings->rom_plus3_0  );
  case 11: return &( settings->rom_plus3_1  );
  case 12: return &( settings->rom_plus3_2  );
  case 13: return &( settings->rom_plus3_3  );
  case 14: return &( settings->rom_tc2048   );
  case 15: return &( settings->rom_tc2068_0 );
  case 16: return &( settings->rom_tc2068_1 );
  case 17: return &( settings->rom_pentagon_0 );
  case 18: return &( settings->rom_pentagon_1 );
  case 19: return &( settings->rom_pentagon_2 );
  case 20: return &( settings->rom_pentagon_3 );
  case 21: return &( settings->rom_scorpion_0 );
  case 22: return &( settings->rom_scorpion_1 );
  case 23: return &( settings->rom_scorpion_2 );
  case 24: return &( settings->rom_scorpion_3 );
  case 25: return &( settings->rom_plus3e_0 );
  case 26: return &( settings->rom_plus3e_1 );
  case 27: return &( settings->rom_plus3e_2 );
  case 28: return &( settings->rom_plus3e_3 );
  case 29: return &( settings->rom_spec_se_0 );
  case 30: return &( settings->rom_spec_se_1 );
  case 31: return &( settings->rom_interface_i );
  case 32: return &( settings->rom_ts2068_0 );
  case 33: return &( settings->rom_ts2068_1 );
  case 34: return &( settings->rom_plusd );
  default: return NULL;
  }
}

int
settings_set_string( char **string_setting, const char *value )
{
  /* No need to do anything if the two strings are in fact the
     same pointer */
  if( *string_setting == value ) return 0;

  if( *string_setting) free( *string_setting );
  *string_setting = strdup( value );
  if( !( *string_setting ) ) {
    ui_error( UI_ERROR_ERROR, "out of memory at %s:%d", __FILE__, __LINE__ );
    return 1;
  }

  return 0;
}

int
settings_free( settings_info *settings )
{
CODE

foreach my $name ( sort keys %options ) {
    if( $options{$name}->{type} eq 'string' ) {
	print "  if( settings->$name ) free( settings->$name );\n";
    }
}

print hashline( __LINE__ ), << 'CODE';

  return 0;
}

int
settings_end( void )
{
#ifdef HAVE_LIB_XML2
  if( settings_current.autosave_settings )
    settings_write_config( &settings_current );
#endif			/* #ifdef HAVE_LIB_XML2 */

  settings_free( &settings_current );

  return 0;
}
CODE
