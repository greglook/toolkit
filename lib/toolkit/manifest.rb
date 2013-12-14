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

    # Loads the manifest file in the given package set directory.
    #
    # `root`:: location containing manifest file and packages
    # `file`:: optional manifest filename override
    def initialize(root, manifest=MANIFEST_FILE)
      @root = Pathname.new(root).freeze
      raise "No package set located at #{@root}" unless @root.dir?

      @name = @root.basename.freeze

      manifest_path = @root + manifest
      raise "No readable package manifest at #{manifest_path}" unless manifest_path.readable?

      @packages = { }
      instance_eval manifest_path.readlines.join, manifest_path.to_s, 1
      @packages.freeze
    end

    private

    # Registers a package. Meant to be called from the manifest file.
    def package(name, options={})
      root = options[:root] || (@root + name)
      @packages[name] = Package.new(name, root, options)
    end

    # Tests whether a command with the given name exists in the PATH.
    def installed?(command)
      `which #{command} 2> /dev/null`
      $?.success?
    end
  end
end
