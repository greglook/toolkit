Toolkit
=======

This is a tool which provides a shared location for environment configuration
(colloquially, 'dotfiles'), utility scripts, and any other kinds of files which
you want to keep in sync across multiple user accounts on different machines.
This enables new user accounts to be set up quickly with a common set of such
files.

You can think of this as a very lightweight package manager for your home
directory.

Packages
--------
Files are separated into _packages_ specific to certain programs or
environments, which lets you tailor the installation to the local requirements.
Packages may be _selected_ for installation; some are selected by default,
others based on environment detection, and you can of course manually set any
package's selection state.

Packages are further separated into _package sets_ based on their directory
structure. This is primarily to allow for the package files to be maintained
separately from the toolkit code itself. This way you can install packages from
multiple sources, and potentially keep sensitive configs in non-public repos.

Package installation creates symlinks from the user's `$HOME` directory to the
files in the toolkit package. Thus, edits to the normal file paths are also
edits to the git repository, which can then be committed and shared with the
toolkits on other hosts.

Usage
-----
To set up a toolkit for a new user account, first clone the toolkit repository
into a local folder:

```bash
$ mkdir ~/util && cd ~/util
$ git clone git@github.com:greglook/toolkit.git
$ cd toolkit
```

Next clone your desired package sets into the `packages` directory. For
examples, take a look at [my
packages](https://github.com/greglook/toolkit-packages). Once you've got some
packages, run the toolkit script to display which packages are currently
active, select any additional packages you'd like, and build the toolkit:

```bash
$ ./toolkit show
$ ./toolkit enable foo/tools bar/zsh
$ ./toolkit build
```

This will also generate a configuration file at `~/.config/toolkit` with the
installed packages and link information.

Updates
-------
In order to update an installed toolkit, simply pull updates and re-build:

```bash
$ cd ~/util/toolkit/packages/foo
$ git pull
$ cd ../..
$ ./toolkit build
```

License
-------
This is free and unencumbered software released into the public domain.
See the UNLICENSE file for more information.
