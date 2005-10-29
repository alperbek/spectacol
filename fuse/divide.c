/* divide.c: DivIDE interface routines
   Copyright (c) 2005 Matthew Westcott

   $Id$

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
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

   Author contact information:

   E-mail: Philip Kendall <pak21-fuse@srcf.ucam.org>
   Postal address: 15 Crescent Road, Wokingham, Berks, RG40 2DB, England

*/

#include <config.h>

#include "machine.h"
#include "periph.h"
#include "settings.h"
#include "ui/ui.h"
#include "divide.h"

/* Private function prototypes */

static libspectrum_byte divide_ide_read( libspectrum_word port, int *attached );
static void divide_ide_write( libspectrum_word port, libspectrum_byte data );
static void divide_control_write( libspectrum_word port, libspectrum_byte data );
static void divide_control_write_internal( libspectrum_byte data );
void divide_page( void );
void divide_unpage( void );

/* Data */

const periph_t divide_peripherals[] = {
  { 0x00e3, 0x00a3, divide_ide_read, divide_ide_write },
  { 0x00ff, 0x00e3, NULL, divide_control_write },
};

const size_t divide_peripherals_count =
  sizeof( divide_peripherals ) / sizeof( periph_t );

static const libspectrum_byte DIVIDE_CONTROL_CONMEM = 0x80;
static const libspectrum_byte DIVIDE_CONTROL_MAPRAM = 0x40;

int divide_automapping_enabled = 0;
int divide_active = 0;
static libspectrum_byte divide_control;

/* divide_automap tracks opcode fetches to entry and exit points to determine
   whether DivIDE memory *would* be paged in at this moment if mapram / wp
   flags allowed it */
static int divide_automap = 0;

#define DIVIDE_PAGES 4
#define DIVIDE_PAGE_LENGTH 0x2000
static libspectrum_byte divide_ram[ DIVIDE_PAGES ][ DIVIDE_PAGE_LENGTH ];
static libspectrum_byte divide_eprom[ DIVIDE_PAGE_LENGTH ];

/* Housekeeping functions */

void
divide_reset( void )
{
  if( !settings_current.divide_enabled ) return;
  
  /* FIXME: MAPRAM bit of control register should be preserved on reset,
     but cleared on hard restart */
  divide_control = 0;
  divide_automap = 0;
  divide_refresh_page_state();
}

/* Port read/writes */

libspectrum_byte
divide_ide_read( libspectrum_word port GCC_UNUSED, int *attached )
{
  if( !settings_current.divide_enabled ) return 0xff;
  return 0xff;
  
  /* *attached = 1;
  return 42; */
}

static void
divide_ide_write( libspectrum_word port GCC_UNUSED, libspectrum_byte data GCC_UNUSED )
{
  if( !settings_current.divide_enabled ) return;
  
  return;
}

static void
divide_control_write( libspectrum_word port GCC_UNUSED, libspectrum_byte data )
{
  int old_mapram;

  if( !settings_current.divide_enabled ) return;
  
  /* MAPRAM bit cannot be reset, only set */
  old_mapram = divide_control & DIVIDE_CONTROL_MAPRAM;
  divide_control_write_internal( data | old_mapram );
}

static void
divide_control_write_internal( libspectrum_byte data )
{
  divide_control = data;
  divide_refresh_page_state();
}

void
divide_set_automap( int state )
{
  divide_automap = state;
  divide_refresh_page_state();
}

void
divide_refresh_page_state( void )
{
  if( divide_control & DIVIDE_CONTROL_CONMEM ) {
    /* always paged in if conmem enabled */
    divide_page();
  } else if( settings_current.divide_wp
    || ( divide_control & DIVIDE_CONTROL_MAPRAM ) ) {
    /* automap in effect */
    if( divide_automap ) {
      divide_page();
    } else {
      divide_unpage();
    }
  } else {
    divide_unpage();
  }
}

void
divide_page( void )
{
  divide_active = 1;
  machine_current->ram.romcs = 1;
  machine_current->memory_map();
}

void
divide_unpage( void )
{
  divide_active = 0;
  machine_current->ram.romcs = 0;
  machine_current->memory_map();
}

void
divide_memory_map( void )
{
  /* low bits of divide_control register give page number to use in upper
     bank; only lowest two bits on original 32K model */
  int upper_ram_page = divide_control & (DIVIDE_PAGES - 1);
  
  if( divide_control & DIVIDE_CONTROL_CONMEM ) {
    memory_map_romcs[0].page = divide_eprom;
    memory_map_romcs[0].writable = !settings_current.divide_wp;
    memory_map_romcs[1].page = divide_ram[ upper_ram_page ];
    memory_map_romcs[1].writable = 1;
  } else {
    if( divide_control & DIVIDE_CONTROL_MAPRAM ) {
      memory_map_romcs[0].page = divide_ram[3];
      memory_map_romcs[0].writable = 0;
      memory_map_romcs[1].page = divide_ram[ upper_ram_page ];
      memory_map_romcs[1].writable = ( upper_ram_page != 3 );
    } else {
      memory_map_romcs[0].page = divide_eprom;
      memory_map_romcs[0].writable = 0;
      memory_map_romcs[1].page = divide_ram[ upper_ram_page ];
      memory_map_romcs[1].writable = 1;
    }
  }

  memory_map_read[0] = memory_map_write[0] = memory_map_romcs[0];
  memory_map_read[1] = memory_map_write[1] = memory_map_romcs[1];
}