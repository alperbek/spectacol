/* wav.c: Routines for handling WAV raw audio files
   Copyright (c) 2007 Fredrick Meunier

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

   E-mail: fredm@spamcop.net

*/

#include <config.h>
#include <string.h>

#ifdef HAVE_LIB_AUDIOFILE

#include <audiofile.h>

#include "internals.h"
#include "tape_block.h"

libspectrum_error
libspectrum_wav_read( libspectrum_tape *tape, const char *filename )
{
  libspectrum_byte *buffer; size_t length;
  libspectrum_byte *tape_buffer; size_t tape_length;
  libspectrum_error error;
  libspectrum_tape_block *block = NULL;
  int frames;

  /* Our filehandle from libaudiofile */
  AFfilehandle handle;

  /* The track we're using in the file */
  int track = AF_DEFAULT_TRACK; 

  if( !filename ) {
    libspectrum_print_error(
      LIBSPECTRUM_ERROR_LOGIC,
      "libspectrum_wav_read: no filename provided - wav files can only be loaded from a file"
    );
    return LIBSPECTRUM_ERROR_LOGIC;
  }

  handle = afOpenFile( filename, "r", NULL );
  if( handle == AF_NULL_FILEHANDLE ) {
    libspectrum_print_error(
      LIBSPECTRUM_ERROR_LOGIC,
      "libspectrum_wav_read: audiofile failed to open file:%s", filename
    );
    return LIBSPECTRUM_ERROR_LOGIC;
  }

  if( afSetVirtualSampleFormat( handle, track, AF_SAMPFMT_UNSIGNED, 8 ) ) {
    afCloseFile( handle );
    libspectrum_print_error(
      LIBSPECTRUM_ERROR_LOGIC,
      "libspectrum_wav_read: audiofile failed to set virtual sample format"
    );
    return LIBSPECTRUM_ERROR_LOGIC;
  }

  length = afGetFrameCount( handle, track );

  tape_length = length;
  if( tape_length%8 ) tape_length += 8 - (tape_length%8);

  buffer = calloc( tape_length, 1);
  if( !buffer ) {
    afCloseFile( handle );
    libspectrum_print_error(
      LIBSPECTRUM_ERROR_MEMORY,
      "libspectrum_wav_read: failed to allocate memory for block data"
    );
    return LIBSPECTRUM_ERROR_MEMORY;
  }

  frames = afReadFrames( handle, track, buffer, length );
  if( frames == -1 ) {
    free( buffer );
    afCloseFile( handle );
    libspectrum_print_error(
      LIBSPECTRUM_ERROR_CORRUPT,
      "libspectrum_wav_read: can't calculate number of frames in audio file"
    );
    return LIBSPECTRUM_ERROR_CORRUPT;
  }

  if( !length ) {
    free( buffer );
    afCloseFile( handle );
    libspectrum_print_error(
      LIBSPECTRUM_ERROR_CORRUPT,
      "libspectrum_wav_read: empty audio file, nothing to load"
    );
    return LIBSPECTRUM_ERROR_CORRUPT;
  }

  if( frames != length ) {
    free( buffer );
    afCloseFile( handle );
    libspectrum_print_error(
      LIBSPECTRUM_ERROR_CORRUPT,
      "libspectrum_wav_read: read %d frames, but expected %ld\n", frames, length
    );
    return LIBSPECTRUM_ERROR_CORRUPT;
  }

  /* Get a new block */
  error = libspectrum_tape_block_alloc( &block,
                                        LIBSPECTRUM_TAPE_BLOCK_RAW_DATA );
  if( error ) return error;

  /* 44100 Hz 79 t-states 22050 Hz 158 t-states */
  libspectrum_tape_block_set_bit_length( block,
                                         3500000/afGetRate( handle, track ) );
  libspectrum_tape_block_set_pause     ( block, 0 );
  libspectrum_tape_block_set_bits_in_last_byte( block, length%8 ? length%8 : 8 );
  libspectrum_tape_block_set_data_length( block, tape_length/8 );

  tape_buffer = calloc( tape_length/8, 1 );

  libspectrum_byte *from = buffer;
  libspectrum_byte *to = tape_buffer;
  length = tape_length;
  do {
    libspectrum_byte val = 0;
    int i;
    for( i = 7; i >= 0; i-- ) {
      if( *from++ > 127 ) val |= 1 << i;
    }
    *to++ = val;
  } while ((length -= 8) > 0);

  libspectrum_tape_block_set_data( block, tape_buffer );

  /* Finally, put the block into the block list */
  error = libspectrum_tape_append_block( tape, block );
  if( error ) {
    free( buffer );
    libspectrum_tape_block_free( block );
    return error;
  }

  if( afCloseFile( handle ) ) {
    free( buffer );
    libspectrum_print_error(
      LIBSPECTRUM_ERROR_UNKNOWN,
      "libspectrum_wav_read: failed to close audio file"
    );
    return LIBSPECTRUM_ERROR_UNKNOWN;
  }

  free( buffer );

  /* Successful completion */
  return LIBSPECTRUM_ERROR_NONE;
}

#endif    /* #ifdef HAVE_LIB_AUDIOFILE */