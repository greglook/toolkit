# Defines the Toolkit::Config class.

require 'pathname'
require 'yaml'

class Toolkit

# A class to manage user-specific toolkit configuration and other persistent
# state.
#
# Author:: Greg Look
class Config
  attr_reader :path, :selected
  attr_accessor :installed, :links

  # Loads toolkit configuration from the given file path.
  #
  # +path+:: location of config file to load
  def initialize(path)
    @path = Pathname.new(path)

    config = @path.exist? && @path.open{|f| YAML.load(f) } || { }

    @installed = config['installed'] || []
    @selected  = config['selected']  || {}
    @links     = config['links']     || {}
  end

  # Saves bag configuration.
  def save
    config = {
      'installed' => @installed,
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
