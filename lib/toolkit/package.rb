# Defines the Toolkit::Package class.

require 'pathname'

class Toolkit
  # A package is a unit of related, deployable files. These may be environment
  # customizations, configuration files, scripts, and so on.
  #
  # Author:: Greg Look
  class Package
    attr_reader :name, :source, :dest, :links
    attr_accessor :selected

    # Ignored files ensure the directory they are located in is created, but are
    # not linked to from that directory.
    IGNORED_FILES = ['.keep']

    # Creates a new package.
    #
    # `name`:: package designation
    # `source`:: directory containing the package's files
    # `options`:: hash accepting various optional settings
    # - `:default`:: if true, package will be selected by default
    # - `:when`:: alias for `:default`
    # - `:dotfiles`:: if true, all root-level files in the package will be
    #                 prefixed with a period. Alternately, an array of files may
    #                 be provided, which will be prefixed if the paths match.
    def initialize(name, source, options={})
      raise "Package source root '#{source}' is not a directory" unless File.directory? source

      @name = name.to_s.freeze
      @source = Pathname.new(source).freeze
      @dest = Pathname.new(options[:into] || "").freeze
      @selected = !!(options[:default] || options[:when])
      @links = { }

      populate_links do |path|
        if options[:dotfiles] == true
          ".#{path.basename}" if path.parent == @source
        elsif options[:dotfiles].kind_of? Array
          relpath = path.relative_path_from(@source)
          ".#{path.basename}" if options[:dotfiles].include? relpath.to_s
        end
      end

      @links.freeze
    end

    private

    # Populates the link hash from the files in the package source.
    #
    # `&block`:: proc to map pathnames to a specific name for that file.
    def populate_links
      stack = [[[], @source]]
      until stack.empty?
        roots, dir = *stack.pop
        dir.children.each do |child|
          name = block_given? && yield(child) || child.basename.to_s
          path = roots + [name]

          if child.directory?
            stack.push [path, child]
          else
            if IGNORED_FILES.include? child.basename.to_s
              @links[File.join(roots)] = true
            else
              @links[File.join(path)] = child.relative_path_from(@source).to_s
            end
          end
        end
      end
    end
  end
end
