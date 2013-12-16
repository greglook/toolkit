# Defines the Toolkit class.

require 'pathname'
require 'toolkit/config'
require 'toolkit/manifest'
require 'yaml'


# This class provides some static convenience functions for interacting with
# the toolkit library.
#
# Author:: Greg Look
class Toolkit

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

    # check existing packages
    (config.installed & active).sort.each do |name|
      log 'CHECK', ":: #{name} ::"
      install package_root, packages[name], links, mount
    end

    # install new packages
    (active - config.installed).sort.each do |name|
      log 'INSTALL', ":: #{name} ::"
      install package_root, packages[name], links, mount
    end

    # remove old packages
    (config.installed - active).sort.each do |name|
      log 'REMOVE', ":: #{name} ::"
    end

    # clean dangling symlinks and empty directories
    (config.links.keys - links.keys).sort.each do |path|
      dest = mount + path
      if dest.symlink?
        log '-LINK', path
        dest.delete
      end
      dir = dest.parent
      while dir != mount && dir.directory? && dir.children.empty?
        log '-DIR', dir.relative_path_from(mount)
        dir.delete
        dir = dir.parent
      end
    end

    config.installed = active
    config.links = links
  end


  private


  # Prints a formatted message.
  def self.log(type, msg)
    puts "%10s %s" % ["[%s]" % type, msg]
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
          log 'CONFLICT', "#{path} -> #{link} : cannot replace link with directory"
        else
          links[path.to_s] = true
          if dest.directory?
            #log 'EXISTS', "#{path}/"
          else
            log '+DIR', "#{path}/"
            dest.mkpath
          end
        end

      # target is a link to a file
      elsif package.links[from]
        target = (package.source + package.links[from]).relative_path_from(package_root)
        src = package_root + target

        if links[path] == true
          log 'CONFLICT', "#{path}/ : cannot replace directory with link to #{target}"
        elsif links[path]
          log 'CONFLICT', "#{path} -> #{links[path]} : existing link conflicts with #{target}"
        else
          links[path.to_s] = target.to_s

          unless dest.parent.directory?
            log '+DIR', "#{path.parent}/"
            dest.parent.mkpath
          end

          if dest.symlink?
            if dest.readlink == src
              #log 'EXISTS', "#{path} -> #{target}"
            else
              log '~LINK', "#{path} -> #{target}"
              dest.delete
              dest.make_symlink(src)
            end
          else
            if dest.exist?
              log 'CONFLICT', "#{path} : path is a #{dest.ftype}, expected a symlink"
            else
              log '+LINK', "#{path} -> #{target}"
              dest.make_symlink(src)
            end
          end
        end
      end
    end
  end
end
