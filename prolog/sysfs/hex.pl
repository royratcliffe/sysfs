/*  File:    sysfs/hex.pl
    Author:  Roy Ratcliffe
    Created: Jun  6 2024
    Purpose: Hexadecimal Conversion Utilities

Copyright (c) 2025, Roy Ratcliffe, Northumberland, United Kingdom

Permission is hereby granted, free of charge,  to any person obtaining a
copy  of  this  software  and    associated   documentation  files  (the
"Software"), to deal in  the   Software  without  restriction, including
without limitation the rights to  use,   copy,  modify,  merge, publish,
distribute, sub-license, and/or sell copies  of   the  Software,  and to
permit persons to whom the Software is   furnished  to do so, subject to
the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT  WARRANTY OF ANY KIND, EXPRESS
OR  IMPLIED,  INCLUDING  BUT  NOT   LIMITED    TO   THE   WARRANTIES  OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR   PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS  OR   COPYRIGHT  HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY,  WHETHER   IN  AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM,  OUT  OF   OR  IN  CONNECTION  WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

:- module(sysfs_hex, [bytes_to_hex/3, byte_to_hex/2]).

/** <module> Hexadecimal Conversion Utilities
 *
 * This module provides utilities for converting between bytes and
 * hexadecimal strings. It includes predicates for converting a list of
 * bytes to a hexadecimal string with a specified delimiter, as well as
 * converting a single byte to a two-digit hexadecimal string.
 *
 * @author Roy Ratcliffe
 * @version 1.0
 * @license MIT
 */

%!  bytes_to_hex(+Bytes, +Delimiter, -HexString) is det.
%
%   Converts a list of bytes (codes) to a hexadecimal string with a specified
%   delimiter between bytes. The Bytes argument is a list of codes to convert, Delimiter is
%   the string to insert between hexadecimal representations of bytes, and
%   HexString is the resulting hexadecimal string. For example, bytes_to_hex([255,
%   0, 128], ' ', HexString) will unify HexString with "ff 00 80".
%
%   @arg Bytes is a list of integers between 0 and 255 representing bytes.
%   @arg Delimiter is a string to insert between hexadecimal representations of bytes.
%   @arg HexString is the resulting hexadecimal string.

bytes_to_hex(Bytes, Delimiter, HexString) :-
    maplist(byte_to_hex, Bytes, HexStrings),
    atomic_list_concat(HexStrings, Delimiter, HexString).

%!  byte_to_hex(+Byte, -HexString) is det.
%
%   Converts a byte (integer between 0 and 255) to a two-digit hexadecimal string.
%   For example, byte_to_hex(255, HexString) will unify HexString with "ff".
%
%   @arg Byte is an integer between 0 and 255 representing a byte.
%   @arg HexString is the resulting two-digit hexadecimal string.

byte_to_hex(Byte, HexString) :- format(string(HexString), '~|~`0t~16r~2+', [Byte]).
