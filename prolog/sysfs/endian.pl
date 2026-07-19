/*  File:    sysfs/endian.pl
    Author:  Roy Ratcliffe
    Created: Aug 28 2023
    Purpose: Big- and Little-Endian Grammars

Copyright (c) 2023, Roy Ratcliffe, Northumberland, United Kingdom

Permission is hereby granted, free of charge,  to any person obtaining a
copy  of  this  software  and    associated   documentation  files  (the
"Software"), to deal in  the   Software  without  restriction, including
without limitation the rights to  use,   copy,  modify,  merge, publish,
distribute, sublicense, and/or sell  copies  of   the  Software,  and to
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

:- module(sysfs_endian,
          [ endian//3 % ?BigOrLittle, ?Width, ?Value
          , big_endian//2 % ?Width, ?Value
          , little_endian//2 % ?Width, ?Value
          ]).
:- autoload(library(dcg/basics), [remainder/3]).

/** <module> Big- and Little-Endian Grammars
 *
 * This module provides DCG grammars for reading and writing big- and
 * little-endian integer values of arbitrary bit width (multiples of eight). The grammars
 * can be used to parse or generate binary data in a platform-independent
 * manner.
 *
 * @author Roy Ratcliffe
 * @version 1.0
 * @license MIT
 */

%!  endian(?BigOrLittle, ?Width, ?Value)// is semidet.
%
%   Applies `big` or `little`-endian  ordering   grammar  to  an integer
%   Value of any Width.
%
%   Divides the problem in two:  firstly   the  'endianness'  span which
%   unifies an input or output phrase with the bit width of a value, and
%   secondly the shifted bitwise-OR phase  that translates between coded
%   eight-bit octets and un-encoded integers of unlimited bit width by
%   accumulation.
%
%   @arg BigOrLittle is the atom `big` or `little` specifying the
%   endianness of the coded Value.
%
%   @arg Width is the multiple-of-eight bit width of the endian-ordered
%   octet phrase.
%
%   @arg Value is the un-encoded integer value of unlimited bit width.

endian(big, Width, Value) --> big_endian(Width, Value).
endian(little, Width, Value) --> little_endian(Width, Value).

%!  big_endian(?Width, ?Value)// is semidet.
%
%   Implements the grammar for endian(big, Width, Value) super-grammar.
%
%   In (-, +)  mode  the  accumulator   recurses  _first_  and  then the
%   residual Value_ merges with the accumulated  Value because the first
%   octet code is the most-significant byte  of the value for big-endian
%   integer representations, rather than the   least-significant. The `0
%   =< H, H =< 255` guard conditions   ensure failure for non-octet code
%   items in the list.

big_endian(Width, Value) -->
    { var(Value), !
    },
    endianness(Width, Octets),
    { big_endian(Octets, 0, Value)
    }.
big_endian(Width, Value) -->
    endianness(Width, Octets),
    { big_endian_(Octets, Value, _)
    }.

big_endian([], Value, Value).
big_endian([H|T], Value0, Value) :-
    acc(H, Value0, Value_),
    big_endian(T, Value_, Value).

big_endian_([], Value, Value).
big_endian_([H|T], Value0, Value) :-
    big_endian_(T, Value0, Value_),
    acc_(H, Value_, Value).

acc(H, Value0, Value_) :-
    0 =< H,
    H =< 255,
    Value_ is H \/ (Value0 << 8).

acc_(H, Value_, Value) :-
    H is Value_ /\ 16'ff,
    Value is Value_ >> 8.

%!  little_endian(?Width, ?Value)// is semidet.
%
%   Implements endian(little, Width, Value) grammar.
%
%   Little-endian accumulators perform the same   logical unification as
%   for big-endian only in reverse. The  only difference between big and
%   little: recurse first or recurse last.   Apart  from that subtle but
%   essential difference, the inner computation behaves identically.

little_endian(Width, Value) -->
    { var(Value), !
    },
    endianness(Width, Octets),
    { little_endian(Octets, 0, Value)
    }.
little_endian(Width, Value) -->
    endianness(Width, Octets),
    { little_endian_(Octets, Value, _)
    }.

little_endian([], Value, Value).
little_endian([H|T], Value0, Value) :-
    little_endian(T, Value0, Value_),
    %
    %   0 =< H,
    %   H =< 255,
    %   Value is H \/ (Value_ << 8),
    %
    acc(H, Value_, Value).

little_endian_([], Value, Value).
little_endian_([H|T], Value0, Value) :-
    %
    %   H is Value0 /\ 16'ff,
    %   Value_ is Value0 >> 8,
    %
    acc_(H, Value0, Value_),
    little_endian_(T, Value_, Value).

%!  endianness(?Width, ?Octets)// is semidet.
%
%   Grammar for finding Octets by  Width.   Unites  difference  lists of
%   octet codes with _zero_ or more items by a width.
%
%   The Width term can be either a   variable or an integer. For unknown
%   widths, the clauses span the remainder  of the difference lists. The
%   length of the outstanding list of   codes determines the final width
%   multiplied by eight.
%
%   The Octets may also  have  variable   items.  The  grammar  does not
%   examine the codes themselves; it only   concerns  the length and its
%   relationship to width. The grammar fails  if   the  width is *not* a
%   multiple of eight.

endianness(Width, Octets) -->
    { var(Width), !
    },
    remainder(Octets),
    { length(Octets, Len),
      Width is Len << 3
    }.
endianness(Width, Octets) -->
    { Width_ is Width /\ 2'111,
      Width_ == 0,
      Len is Width >> 3,
      length(Octets, Len)
    },
    Octets.
