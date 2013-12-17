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

Package installation creates symlinks from the user's `$HOME` directory to the
files in the toolkit package. Thus, edits to the normal file paths are also
edits to the git repository, which can then be committed and shared with the
toolkits on other hosts.

Package Sets
------------
Packages are further separated into _package sets_. This is primarily to allow
for the package files to be maintained separately from the toolkit code itself.
This way you can also install packages from multiple sources, and keep sensitive
packages in non-public repositories.

A package set consists of a directory of packages with a _manifest file_. This
is written in a simple Ruby DSL to define the available packages. Below are
some examples which show the package options:

```ruby
# A simple package with no options.
package 'foo'

# Packages installed by default, when the command 'tmux' is installed, and when
# the shell is 'zsh', respectively.
package 'tools', :default => true
package 'tmux', :dotfiles => true, :when => installed?('tmux')
package 'zsh', :dotfiles => true, :when => ( File.basename(ENV['SHELL']) == 'zsh' )

# Packages may prefix all files with periods or provide an explicit list of
# entries to convert into hidden files.
package 'vim', :dotfiles => true, :when => installed?('vim')
package 'solarized', :dotfiles => ['vim', 'zsh']

# This will install into a subpath of the mount point.
package 'synergy', :into => 'util/synergy'
```

The package definitions should be placed in `manifest.rb` in the package set
directory. For more examples, take a look at [my
packages](https://github.com/greglook/toolkit-packages).

Usage
-----
To set up a toolkit for a new user account, first clone the toolkit repository
into a local folder:

```bash
$ mkdir ~/util && cd ~/util
$ git clone git@github.com:greglook/toolkit.git
$ cd toolkit
```

Next clone your desired package sets into the `packages` directory. Once you've
got some packages, run the toolkit script to display which packages are
currently active, select any additional packages you'd like, and install the
package symlinks:

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
