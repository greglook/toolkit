# Defines the Toolkit class.

require 'pathname'
require 'toolkit/config'
require 'toolkit/manifest'
require 'yaml'


# This is the main class through which the toolkit library is accessed.
#
# Author:: Greg Look
class Toolkit
  attr_reader :mount, :links
  attr_reader :manifest, :config

  # Creates a new toolkit object.
  #
  # +mount+:: directory to install toolkit in.
  def initialize(mount, manifest, config)
    @mount = Pathname.new(mount).realpath.freeze
    @manifest = manifest
    @config = config

    @links = @config.links.dup
  end

  # Delegates package access to the manifest.
  def packages
    @manifest && @manifest.packages
  end

  # Delegates installed package access to the config.
  def installed
    @config && @config.installed
  end

  # Delegates selected package access to the config.
  def selected
    @config && @config.selected
  end

  # Saves the configuration file.
  def save
    @config.save
    puts "Configuration saved"
  end

  # Prints debugging information.
  def debug
    puts "Toolkit object:"
    puts inspect
    puts ""
    puts "Links:"
    length = @config.links.keys.map{|path| path.length }.max
    @config.links.keys.sort.each do |path|
      puts "%-#{length}s -> %s" % [path, @config.links[path]]
    end
  end

  # Prints out information about the toolkit.
  def show
    puts "Toolkit mounted: #{@mount}"
    puts ""
    puts "%10s I A S" % "Package"
    puts "%10s -----" % ('-'*10)
    packages.keys.sort.each do |name|
      puts "%10s %s %s %s" % [
        name,
        installed.include?(name) && '*' || ' ',
        packages[name].selected && '*' || ' ',
        selected[name].nil? && ' ' || selected[name] && 'Y' || 'N'
      ]
    end
  end

  # Enables or disables a package.
  #
  # +name+:: name of package to select
  # +value+:: true to enable a package, false to disable, nil to clear
  def select(name, value)
    unless packages.include? name
      puts "No package named '#{name}' found"
    else
      selected[name] = value.nil? ? nil : !!value
      puts "Package %s %s" % [name, value.nil? && "setting cleared" || value && "enabled" || "disabled"]
    end
  end

  # Installs all selected packages.
  def update
    @links.clear

    # determine active packages
    active = packages.keys.select do |name|
      selected[name].nil? && packages[name].selected || selected[name]
    end

    # check existing packages
    (installed & active).sort.each do |name|
      log 'CHECK', ":: #{name} ::"
      install_links packages[name]
    end

    # install new packages
    (active - installed).sort.each do |name|
      log 'INSTALL', ":: #{name} ::"
      install_links packages[name]
    end

    # remove old packages
    (installed - active).sort.each do |name|
      log 'REMOVED', ":: #{name} ::"
    end

    # clean dangling symlinks
    (@config.links.keys - @links.keys).sort.each do |path|
      dest = @mount + path
      if dest.symlink?
        log '-LINK', path
        dest.delete
      end
      dir = dest.parent
      while dir != @mount && dir.directory? && dir.children.empty?
        log '-DIR', dir.relative_path_from(@mount)
        dir.delete
        dir = dir.parent
      end
    end

    @config.installed = active
    @config.links = @links.dup
    @config.save
  end

  private

  # Prints a formatted message.
  def log(type, msg)
    puts "%10s %s" % ["[%s]" % type, msg]
  end

  # Installs the selected package's links.
  def install_links(package)
    package.links.keys.sort.each do |from|
      path = package.dest + from
      dest = @mount + path

      if package.links[from] == true
        if @links[path] && @links[path] != true
          log 'CONFLICT', "#{path} -> #{@links[path]} : cannot replace link with directory"
        else
          @links[path.to_s] = true
          if dest.directory?
            #log 'EXISTS', "#{path}/"
          else
            log '+DIR', "#{path}/"
            dest.mkpath
          end
        end
      elsif package.links[from]
        target = (package.source + package.links[from]).relative_path_from(@manifest.root)
        src = @manifest.root + target

        if @links[path] == true
          log 'CONFLICT', "#{path}/ : cannot replace directory with link to #{target}"
        elsif @links[path]
          log 'CONFLICT', "#{path} -> #{@links[path]} : existing link conflicts with #{target}"
        else
          @links[path.to_s] = target.to_s

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
