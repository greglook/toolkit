# Defines the Toolkit::Manifest class.

require 'pathname'
require 'toolkit/package'

class Toolkit
  # A package set is a collection of packages, defined by a manifest file.
  #
  # Author:: Greg Look
  class Manifest
    attr_reader :root, :name, :packages

    MANIFEST_FILE = 'manifest.rb'.freeze

    # Attempts to load a package set manifest from the given directory. This
    # function returns a package set on success, or nil if the directory does
    # not contain a manifest or it fails to load.
    #
    # `path`:: package set directory
    def self.load(path)
      manifest = path + MANIFEST_FILE
      Manifest.new(path) if manifest.readable?
    rescue => e
      STDERR.puts "Failed to load manifest from #{path}: #{e.message}"
    end

    # Loads the manifest file in the given package set directory.
    #
    # `path`:: location containing manifest file and packages
    # `name`:: optional name to identify this package set
    # `file`:: optional manifest filename override
    def initialize(path, name=nil, manifest=MANIFEST_FILE)
      @root = Pathname.new(root).freeze
      raise "No package set located at #{@root}" unless @root.dir?

      @name = (name || @root.basename).freeze

      manifest_path = @root + manifest
      raise "No readable package manifest at #{manifest_path}" unless manifest_path.readable?

      @packages = { }
      instance_eval manifest_path.readlines.join, manifest_path.to_s, 1
      @packages.freeze
    end

    private

    # Sets the package set name. Meant to be called from the manifest file.
    def package_set(name)
      @name = name
    end

    # Registers a package. Meant to be called from the manifest file.
    def package(name, options={})
      root = @root + name
      @packages[name] = Package.new(name, root, options)
    end

    # Tests whether a command with the given name exists in the PATH.
    def installed?(command)
      `which #{command} 2> /dev/null`
      $?.success?
    end
  end
end
