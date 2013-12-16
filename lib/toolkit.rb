# Defines the Toolkit class.

require 'pathname'
require 'toolkit/ansi'
require 'toolkit/config'
require 'toolkit/manifest'
require 'yaml'


# This class provides some static convenience functions for interacting with
# the toolkit library.
#
# Author:: Greg Look
module Toolkit

  # Loads multiple package sets from the given directory. Returns a map of
  # namespaced package names to `Package` objects.
  #
  # `package_root`:: directory containing package set directories
  def self.load_packages(package_root)
    package_sets = []
    package_root.children.each do |path|
      begin
        manifest = Manifest.load(path)
        package_sets << manifest if manifest
      rescue => e
        STDERR.puts "Failed to load package set from #{path} - #{e.message}"
      end
    end

    packages = {}
    package_sets.each do |manifest|
      manifest.packages.each do |name, package|
        pkg_name = "#{manifest.name}/#{name}"
        if packages[pkg_name]
          STDERR.puts "Package name conflict: #{pkg_name}"
        else
          packages[pkg_name] = package
        end
      end
    end

    packages
  end


  # Installs all selected packages.
  def self.build!(package_root, config, packages, mount)
    links = {}

    # determine active packages
    active = packages.keys.select do |name|
      package = packages[name]
      selected = config.selected?(name)
      package && (selected.nil? && package.active? || selected)
    end

    # determine longest package name
    name_width = packages.keys.map{|name| name.length }.max

    # check existing packages
    (config.installed & active).sort.each do |name|
      log :light_blue, 'CHECK', ANSI.colorize(name, :light_cyan)
      install package_root, packages[name], links, mount
    end

    # install new packages
    (active - config.installed).sort.each do |name|
      log :light_green, 'INSTALL', ANSI.colorize(name, :light_cyan)
      install package_root, packages[name], links, mount
    end

    # remove old packages
    (config.installed - active).sort.each do |name|
      log :light_red, 'REMOVE', ANSI.colorize(name, :light_cyan)
    end

    # clean dangling symlinks and empty directories
    (config.links.keys - links.keys).sort.each do |path|
      dest = mount + path
      if dest.symlink?
        log :red, '-LINK', path
        dest.delete
      end
      dir = dest.parent
      while dir != mount && dir.directory? && dir.children.empty?
        log :red, '-DIR', dir.relative_path_from(mount)
        dir.delete
        dir = dir.parent
      end
    end

    config.installed = active
    config.links = links
  end


  private


  # Prints a formatted message.
  def self.log(color, type, msg)
    spaces = " "*(10 - type.length)
    header = "[%s]" % ANSI.colorize(type, color)
    puts "%s%s %s" % [spaces, header, msg]
  end


  # Installs the selected package by symlinking its files. Updates the given
  # link map with the new information.
  def self.install(package_root, package, links, mount)
    package.links.keys.sort.each do |from|
      path = package.dest + from
      dest = mount + path
      current_link = links[path.to_s]

      # target is an empty directory
      if package.links[from] == true
        if current_link && current_link != true
          log :light_red, 'CONFLICT', "#{path} -> #{link} : cannot replace link with directory"
        else
          links[path.to_s] = true
          if dest.directory?
            log :blue, 'EXISTS', "#{path}/" if $verbose
          else
            log :green, '+DIR', "#{path}/"
            dest.mkpath
          end
        end

      # target is a link to a file
      elsif package.links[from]
        target = (package.source + package.links[from]).relative_path_from(package_root)
        src = package_root + target

        if links[path] == true
          log :light_red, 'CONFLICT', "#{path}/ : cannot replace directory with link to #{target}"
        elsif links[path]
          log :light_red, 'CONFLICT', "#{path} -> #{links[path]} : existing link conflicts with #{target}"
        else
          links[path.to_s] = target.to_s

          unless dest.parent.directory?
            log :green, '+DIR', "#{path.parent}/"
            dest.parent.mkpath
          end

          if dest.symlink?
            if dest.readlink == src
              log :blue, 'EXISTS', "#{path} -> #{target}" if $verbose
            else
              log :blue, '~LINK', "#{path} -> #{target}"
              dest.delete
              dest.make_symlink(src)
            end
          else
            if dest.exist?
              log :light_red, 'CONFLICT', "#{path} : path is a #{dest.ftype}, expected a symlink"
            else
              log :green, '+LINK', "#{path} -> #{target}"
              dest.make_symlink(src)
            end
          end
        end
      end
    end
  end
end
