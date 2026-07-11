/*  File:    sysfs/sysfs.pl
    Author:  Roy Ratcliffe
    Created: Dec  9 2024
    Purpose: Sysfs Virtual File System

Copyright (c) 2026, Roy Ratcliffe, Northumberland, United Kingdom

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

:- module(sysfs,
          [ sysfs_entry/3 % +Class, -Entry, ?Entries:list
          , sysfs_exported_with_time_limit/3 % +File, -Abs, +Options:list
          ]).
:- use_module(library(sysfs/dcg_files)).

/** <module> Sysfs Virtual File System
 *
 * This module provides predicates to  access   the  sysfs  virtual file
 * system in Linux. It allows developers to find the path to sysfs class
 * directories and files  in  those   directories.  The  predicates  are
 * designed to be flexible and can  be   used  in various ways to access
 * sysfs information.
 *
 * @author Roy Ratcliffe
 * @version 1.0
 * @license MIT
 */

% The line encoding setting specifies the   encoding to use when reading
% and writing files. The default is  ASCII,   but  it  can be changed to
% UTF-8 if needed. This  setting  is   used  by  the  read_file_as/2 and
% write_file_as/3 predicates to determine how  to interpret the contents
% of the file being read or written.
:- setting(line_encoding, oneof([ascii, utf8]), ascii, 'Line encoding for reading and writing files.').

%!  sysfs_entry(+Class, -Entry, ?Entries:list) is nondet.
%
%   True when Entry is a directory entry   in the sysfs class Class, and
%   Entries is the list of all nested   directory entries in that class.
%   For example, sysfs_entry(gpio, Entry, Entries) will unify Entry with
%   each entry in the /sys/class/gpio directory,   and  Entries with the
%   list of all nested entries in that directory.
%
%   Spans the sysfs virtual file system to  find directory entries for a
%   given class non-deterministically. Leaves a  choice point even after
%   finding an entry, so that backtracking can   find all entries in the
%   class.
%
%   @arg Class is the name of the sysfs class, such as gpio, block, net,
%   etc.
%
%   @arg Entry is a directory entry in the specified class.
%
%   @arg Entries is the list of all nested directory entries in the
%   specified class.

sysfs_entry(Class, Entry, Entries) :-
    absolute_file_name(sysfs_class(Class), Directory),
    (   ground(Entries)
    ->  phrase(directory_entry(Directory, Entry), Entries),
        % Cut to prevent backtracking after finding a matching entry, since only
        % one possible path exists for a given Entry in a given Class. This is
        % because the sysfs virtual file system, like other file systems, has a
        % unique path for each file or directory. Therefore, once a matching
        % entry is found, there is no need to continue searching for other
        % entries in the same class, as they will not match the specified Entry.
        !
    ;   phrase(directory_entry(Directory, Entry), Entries)
    ).

:- setting(sysfs_exported_time_limit, number, 1, 'Time limit for sysfs exported calls in seconds').
:- setting(sysfs_exported_delay_time, number, 0.01, 'Delay time between sysfs exported call retries in seconds').

%!  sysfs_exported_with_time_limit(+File, -Abs, +Options:list) is semidet.
%
%   True when File is a file in the   sysfs  virtual file system that is
%   exported and accessible, and Abs is the  absolute path of that file.
%   The predicate will sleep for  the   specified  delay  time and retry
%   until the time limit is reached.
%
%   This predicate amounts to absolute_file_name/3 with a time limit and
%   delay time. It is useful for checking if a file in the sysfs virtual
%   file  system  is  exported   and    accessible,   without   blocking
%   indefinitely.
%
%   @arg File is the name of the file to check.
%
%   @arg Abs is the absolute path of the file if it exists and is
%   accessible.
%
%   @arg Options is a list of   options to pass to absolute_file_name/3.
%   If the file exists and is accessible, sysfs_exported_with_time_limit
%   will succeed. If the file does not   exist  or is not accessible, it
%   will sleep for the specified delay  time   and  retry until the time
%   limit is reached.

sysfs_exported_with_time_limit(File, Abs, Options) :-
    setting(sysfs_exported_time_limit, TimeLimit),
    setting(sysfs_exported_delay_time, DelayTime),
    call_with_time_limit(TimeLimit,
                         (   repeat,
                             absolute_file_name(File, Abs, [file_errors(fail)|Options])
                         ->  !
                         ;   sleep(DelayTime),
                             fail
                         )).

:- multifile user:file_search_path/2.

% This only works on Linux. It may  work on other Unix-like systems, but
% it is not tested. It does not work on Windows because Windows does not
% have a sysfs virtual file system.
%
% Sysfs is a virtual file system that   provides  a view of the kernel's
% device model. It is typically mounted at /sys and contains a hierarchy
% of  directories  and  files  that  represent  the  devices  and  their
% attributes. The file paths in sysfs are   not  real files on disk, but
% rather virtual files that the kernel   generates  on-the-fly when they
% are accessed. The contents of  these  files   can  be  read  to obtain
% information about the devices, and some of   them can be written to in
% order to change the state of the devices.
%
%   sysfs on /sys type sysfs (ro,nosuid,nodev,noexec,relatime)
%
user:file_search_path(sysfs, '/sys').
user:file_search_path(sysfs_class, sysfs(class)).
