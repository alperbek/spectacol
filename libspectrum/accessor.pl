#!/usr/bin/perl -w

# accessor.pl: generate accessor functions
# Copyright (c) 2003 Philip Kendall

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

# E-mail: pak21-fuse@srcf.ucam.org
# Postal address: 15 Crescent Road, Wokingham, Berks, RG40 2DB, England

use strict;

print << "CODE";
/* snap_accessors.c: simple accessor functions for libspectrum_snap
   Copyright (c) 2003 Philip Kendall

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 49 Temple Place, Suite 330, Boston, MA 02111-1307 USA

   Author contact information:

   E-mail: pak21-fuse\@srcf.ucam.org
   Postal address: 15 Crescent Road, Wokingham, Berks, RG40 2DB, England

*/

/* NB: this file is autogenerated from snap_accessors.txt by accessor.pl */

#include "internals.h"

struct libspectrum_snap {

  /* Which machine are we using here? */

  libspectrum_machine machine;

  /* Registers and the like */

  libspectrum_byte a , f ; libspectrum_word bc , de , hl ;
  libspectrum_byte a_, f_; libspectrum_word bc_, de_, hl_;

  libspectrum_word ix, iy; libspectrum_byte i, r;
  libspectrum_word sp, pc;

  libspectrum_byte iff1, iff2, im;

  int halted;			/* Is the Z80 currently HALTed? */

  /* RAM */

  libspectrum_byte *pages[8];

  /* Data from .slt files */

  libspectrum_byte *slt[256];	/* Level data */
  size_t slt_length[256];	/* Length of each level */

  libspectrum_byte *slt_screen;	/* Loading screen */
  int slt_screen_level;		/* The id of the loading screen. Not used
				   for anything AFAIK, but I\'ll copy it
				   around just in case */

  /* Peripheral status */

  libspectrum_byte out_ula; libspectrum_dword tstates;

  libspectrum_byte out_128_memoryport;

  libspectrum_byte out_ay_registerport, ay_registers[16];

  libspectrum_byte out_plus3_memoryport;

  /* Timex-specific bits */
  libspectrum_byte out_scld_hsr, out_scld_dec;

};

/* Initialise a libspectrum_snap structure */
libspectrum_error
libspectrum_snap_alloc( libspectrum_snap **snap )
{
  int i;

  (*snap) = malloc( sizeof( libspectrum_snap ) );
  if( !(*snap) ) {
    libspectrum_print_error( LIBSPECTRUM_ERROR_MEMORY,
			     "libspectrum_snap_alloc: out of memory" );
    return LIBSPECTRUM_ERROR_MEMORY;
  }

  libspectrum_snap_set_a   ( *snap, 0x00 );
  libspectrum_snap_set_f   ( *snap, 0x00 );
  libspectrum_snap_set_bc  ( *snap, 0x0000 );
  libspectrum_snap_set_de  ( *snap, 0x0000 );
  libspectrum_snap_set_hl  ( *snap, 0x0000 );

  libspectrum_snap_set_a_  ( *snap, 0x00 );
  libspectrum_snap_set_f_  ( *snap, 0x00 );
  libspectrum_snap_set_bc_ ( *snap, 0x0000 );
  libspectrum_snap_set_de_ ( *snap, 0x0000 );
  libspectrum_snap_set_hl_ ( *snap, 0x0000 );

  libspectrum_snap_set_ix  ( *snap, 0x0000 );
  libspectrum_snap_set_iy  ( *snap, 0x0000 );
  libspectrum_snap_set_i   ( *snap, 0x00 );
  libspectrum_snap_set_r   ( *snap, 0x00 );
  libspectrum_snap_set_sp  ( *snap, 0x0000 );
  libspectrum_snap_set_pc  ( *snap, 0x0000 );

  libspectrum_snap_set_iff1( *snap, 1 );
  libspectrum_snap_set_iff2( *snap, 1 );
  libspectrum_snap_set_im  ( *snap, 1 );

  libspectrum_snap_set_halted( *snap, 0 );

  for( i = 0; i < 8; i++ ) libspectrum_snap_set_pages( *snap, i, NULL );
  for( i = 0; i < 256; i++ ) {
    libspectrum_snap_set_slt( *snap, i, NULL );
    libspectrum_snap_set_slt_length( *snap, i, 0 );
  }
  libspectrum_snap_set_slt_screen( *snap, NULL );
  libspectrum_snap_set_slt_screen_level( *snap, 0 );

  libspectrum_snap_set_out_ula( *snap, 0x00 );
  libspectrum_snap_set_tstates( *snap, 69664 );
  libspectrum_snap_set_out_128_memoryport( *snap, 0x07 );

  libspectrum_snap_set_out_ay_registerport( *snap, 0x0e );
  for( i = 0; i < 16; i++ ) libspectrum_snap_set_ay_registers( *snap, i, 0 );

  libspectrum_snap_set_out_plus3_memoryport( *snap, 0x08 );

  libspectrum_snap_set_out_scld_hsr( *snap, 0x00 );
  libspectrum_snap_set_out_scld_dec( *snap, 0x00 );

  return LIBSPECTRUM_ERROR_NONE;
}
CODE

while(<>) {

    next if /^\s*$/;
    next if /^\s*#/;

    my( $type, $name, $indexed ) = split;

    if( $indexed ) {

	print << "CODE";

$type
libspectrum_snap_$name( libspectrum_snap *snap, int idx )
{
  return snap->$name\[idx\];
}

void
libspectrum_snap_set_$name( libspectrum_snap *snap, int idx, $type $name )
{
  snap->$name\[idx\] = $name;
}
CODE

    } else {

	print << "CODE";

$type
libspectrum_snap_$name( libspectrum_snap *snap )
{
  return snap->$name;
}

void
libspectrum_snap_set_$name( libspectrum_snap *snap, $type $name )
{
  snap->$name = $name;
}
CODE

    }
}
