# Basic ANSI color printing functions. This checks the global variable
# `$colorize` to determine whether to apply the specified color codes.
#
# Author:: Greg Look

module Toolkit
  module ANSI
    ANSI_SGR = "\e[%sm"

    SGR_NONE      = 0
    SGR_BOLD      = 1
    SGR_UNDERLINE = 3
    SGR_REVERSE   = 7
    SGR_HIDDEN    = 8
    SGR_FG_BASE   = 30
    SGR_BG_BASE   = 40

    COLORS = {
      :black         =>  0,
      :red           =>  1,
      :green         =>  2,
      :yellow        =>  3,
      :blue          =>  4,
      :magenta       =>  5,
      :cyan          =>  6,
      :white         =>  7,
      :gray          =>  7,
      :dark_gray     =>  8,
      :light_black   =>  8,
      :light_red     =>  9,
      :light_green   => 10,
      :light_yellow  => 11,
      :light_blue    => 12,
      :light_magenta => 13,
      :light_cyan    => 14,
      :light_white   => 15
    }

    # Select graphic rendition.
    def self.sgr(*codes)
      ANSI_SGR % codes.join(';')
    end

    # Reset colors.
    def self.reset
      sgr(SGR_NONE)
    end

    # Colorize text.
    def self.colorize(text, color)
      code = COLORS[color]
      if code && $colorize
        codes = if code > 7
                  [SGR_BOLD, SGR_FG_BASE + code - 8]
                else
                  [SGR_FG_BASE + code]
                end
        "%s%s%s" % [sgr(*codes), text, reset]
      else
        text
      end
    end
  end
end
