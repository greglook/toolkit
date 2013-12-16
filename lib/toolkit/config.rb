# Defines the Toolkit::Config class.

require 'pathname'
require 'yaml'

module Toolkit
  # A class to manage user-specific toolkit configuration and other persistent
  # state.
  #
  # Author:: Greg Look
  class Config
    attr_reader :path, :selected
    attr_accessor :installed, :links

    # Loads toolkit configuration from the given file path.
    #
    # `path`:: location of config file to load
    def initialize(path)
      @path = Pathname.new(path)

      config = @path.exist? && @path.open{|f| YAML.load(f) } || { }

      @installed = config['installed'] || []
      @selected  = config['selected']  || {}
      @links     = config['links']     || {}

      @installed.sort!
    end

    # Checks whether the named package is installed.
    def installed?(name)
      @installed.include? name
    end

    # Checks whether the named package is selected.
    def selected?(name)
      @selected[name]
    end

    # Saves the toolkit configuration.
    def save!
      @selected.keys.each do |name|
        @selected.delete(name) if @selected[name].nil?
      end

      config = {
        'installed' => @installed.sort,
        'selected'  => @selected,
        'links'     => @links
      }

      @path.parent.mkpath unless @path.parent.directory?
      @path.open('w') do |file|
        file.puts "# Toolkit configuration written #{Time.now}"
        file.puts "# vim" + ": ft=yaml"
        file.puts config.to_yaml
      end
    end
  end
end
