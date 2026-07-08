/*  File:    sysfs/dcg_files.pl
    Author:  Roy Ratcliffe
    Created: May 11 2025
    Purpose: Neat Filesystem Traversal by DCG

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

:- module(sysfs_dcg_files,
          [ directory_entry//2 % +Directory, ?Entry
          , directory_entry/2  % +Directory, ?Entry
          ]).
:- autoload(library(lists), [member/2]).

/** <module> Neat Filesystem Traversal by DCG
 *
 * This module provides a neat way to traverse a filesystem using a
 * Definite Clause Grammar (DCG). It defines predicates to find files
 * and directories in a given directory, while skipping special entries
 * like '.' and '..'. The main predicates are:
 *
 * - directory_entry//2: A DCG rule that finds files and directories in
 *   the specified directory, yielding each entry as it is found.
 * - directory_entry/2: A predicate that finds files and directories in
 *   the specified directory, yielding each entry as it is found.
 *
 * The predicates are designed to be flexible and can be used in various
 * ways to access files and directories in the filesystem.
 *
 * ---+++ Usage
 *
 * ```
 * ?- phrase(directory_entry('/path/to/directory', Entry), Entries).
 * ```
 *
 * @author Roy Ratcliffe
 * @version 1.0
 * @license MIT
 */

%!  directory_entry(+Directory, ?Entry)// is nondet.
%
%   Neatly traverses a file system using a grammar.
%
%   Finds files and skips the special dot entries. Here, Entry refers
%   to a file. The grammar recursively traverses sub-directories beneath
%   the given Directory and yields every existing file path at
%   Entry. The directory acts as the root of the scan; it joins with
%   the entry to yield the full path of the file, but **not** with the
%   difference list. The second `List` argument of phrase/2 unifies
%   with a list of the corresponding sub-path components *without* the
%   root. The caller sees the full path *and* the relative
%   sub-components.
%
%   Note that the second clause appears in the DCG expanded form with the
%   two hidden arguments: the pre-parsed input list `S0` and the
%   post-parsed output list `S`. For non-directory entries, the input list
%   unifies with nil `[]` because it represents a terminal node in the
%   directory tree, and the post-parsed terms amount to the accumulated
%   `Entries` spanning the sub-directory entries in-between the original
%   root directory and the file itself.
%
%   @arg Directory is the directory to scan.
%
%   @arg Entry is a file or directory entry in the Directory.
%
%   The difference list is a list of sub-path components that join to yield the
%   full path of the file or directory. It is a difference list that accumulates
%   the sub-path components as the grammar traverses the directory tree. It is a
%   list of relative path components that join to yield the full path of the
%   file or directory, but it does not include the root directory.

directory_entry(Directory, Entry) -->
    { exists_directory(Directory),
      !
    },
    % Unify with the next nested directory entry first. This allows a
    % deterministic directory entry to be found without backtracking.
    [Entry_],
    { directory_entry(Directory, Entry_),
      entries_entry([Directory, Entry_], Directory_)
    },
    directory_entry(Directory_, Entry).
directory_entry(Directory, Entry, [], Entries) :-
    entries_entry([Directory|Entries], Entry).

entries_entry(Entries, Entry) :- atomic_list_concat(Entries, /, Entry).

%!  directory_entry(+Directory, -Entry) is nondet.
%!  directory_entry(+Directory, +Entry) is semidet.
%
%   Finds files and directories in the Directory except special files: dot,
%   the current directory; and double dot, the parent directory.
%
%   No need to check if the Entry exists. It does exist at the time of
%   directory iteration. That could easily change by deleting, moving or
%   renaming the entry.
%
%   @arg Directory is the directory to scan. It does not need to be an absolute path.
%   @arg Entry is a file or directory entry in the Directory. It is a relative
%   path that joins with the Directory to yield the full path of the file or
%   directory.

directory_entry(Directory, Entry) :-
    directory_files(Directory, Entries),
    % If Entry is a variable, then find all entries in the directory. If Entry
    % is not a variable, then check if it is a member of the entries in the
    % directory. In either case, skip the special entries '.' and '..'.
    (   var(Entry)
    ->  member(Entry, Entries)
    ;   memberchk(Entry, Entries)
    ),
    \+ special(Entry).

special(.).
special(..).
