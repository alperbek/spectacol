/* symbol_table.c: routines for dealing with the TZX "generalised data"
   symbol table structure
   Copyright (c) 2007 Philip Kendall

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

   E-mail: pak21-fuse@srcf.ucam.org
   Postal address: 15 Crescent Road, Wokingham, Berks, RG40 2DB, England

*/

#include <config.h>

#include "tape_block.h"

libspectrum_dword
libspectrum_tape_generalised_data_symbol_table_symbols_in_block( const libspectrum_tape_generalised_data_symbol_table *table )
{
  return table->symbols_in_block;
}

libspectrum_byte
libspectrum_tape_generalised_data_symbol_table_max_pulses( const libspectrum_tape_generalised_data_symbol_table *table )
{
  return table->max_pulses;
}

libspectrum_byte
libspectrum_tape_generalised_data_symbol_table_symbols_in_table( const libspectrum_tape_generalised_data_symbol_table *table )
{
  return table->symbols_in_table;
}

libspectrum_tape_generalised_data_symbol*
libspectrum_tape_generalised_data_symbol_table_symbol( const libspectrum_tape_generalised_data_symbol_table *table, size_t which )
{
  return &table->symbols[ which ];
}

libspectrum_tape_generalised_data_symbol_edge_type
libspectrum_tape_generalised_data_symbol_type( const libspectrum_tape_generalised_data_symbol *symbol )
{
  return symbol->edge_type;
}

libspectrum_word
libspectrum_tape_generalised_data_symbol_pulse( const libspectrum_tape_generalised_data_symbol *symbol, size_t which )
{
  return symbol->lengths[ which ];
}
