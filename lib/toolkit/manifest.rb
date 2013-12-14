# Defines the Toolkit::Manifest class.

require 'pathname'
require 'toolkit/package'

class Toolkit

# A manifest is a collection of packages.
#
# Author:: Greg Look
class Manifest
  attr_reader :root, :packages

  FILE = 'manifest.rb'.freeze

  # Loads the manifest file in the given package root directory.
  #
  # +root+:: location containing manifest file and packages
  # +file+:: optional filename override
  def initialize(root, file=FILE)
    @root = Pathname.new(root).freeze

    manifest = @root + file
    raise "No readable manifest file at '#{manifest}'" unless manifest.readable?

    @packages = { }
    instance_eval manifest.readlines.join, manifest.to_s, 1
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
