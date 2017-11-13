require "English"

module Dotenv
  module Substitutions
    # Substitute variables in a value.
    #
    #   HOST=example.com
    #   URL="https://$HOST"
    #
    module Variable
      module StringIteration
        def from_longest(s)
          return enum_for(__method__, s) unless block_given?
          (s.length - 1).downto(0).each { |i| yield s[0..i] }
        end

        def from_shortest(s)
          return enum_for(__method__, s) unless block_given?
          0.upto(s.length - 1).each { |i| yield s[0..i] }
        end

        def from_longest_r(s)
          return enum_for(__method__, s) unless block_given?
          0.upto(s.length - 1).each { |i| yield s[i..-1] }
        end

        def from_shortest_r(s)
          return enum_for(__method__, s) unless block_given?
          (s.length - 1).downto(0).each { |i| yield s[i..-1] }
        end
      end

      module StringSubsitution
        include StringIteration

        def longest_match(pat, s)
          from_longest(s).find { |subs| File.fnmatch?(pat, subs) }
        end

        def shortest_match(pat, s)
          from_shortest(s).find { |subs| File.fnmatch?(pat, subs) }
        end

        def longest_match_r(pat, s)
          from_longest_r(s).find { |subs| File.fnmatch?(pat, subs) }
        end

        def shortest_match_r(pat, s)
          from_shortest_r(s).find { |subs| File.fnmatch?(pat, subs) }
        end
      end

      extend StringSubsitution

      class << self
        VARIABLE = /
          (\\)?             # is it escaped with a backslash?
          (\$)              # literal $
          (?!\()            # shouldnt be followed by paranthesis
          \{?               # allow brace wrapping
          ([#!])?           # potential expansion
          ([A-Z0-9_]+)?     # optional alpha nums
          ((?:[^}]|\\[}])*) # potential expansion
          \}?               # closing brace
        /xi

        def call(value, env)
          value.gsub(VARIABLE) do |variable|
            match = $LAST_MATCH_INFO

            if match[1] == '\\'
              variable[1..-1]
            elsif match[4]
              expand(match, env)
            else
              variable
            end
          end
        end

      private

        def expand(match, env)
          resolved = env.fetch(match[4]) { ENV[match[4]] }

          unless match[3].nil? or match[3].empty?
            if match[3] == '#'
              return (resolved || "").length if match[5].nil? or match[5].empty?
              abort "bad expansion!"
            end

            resolved = call("${#{resolved || ""}}", env) if match[3] == '!'
          end

          return resolved || "" if match[5].nil? || match[5].empty?

          dispatch_expansion(resolved, match[5], env)
        end

        def dispatch_expansion(value, unexpanded, env)
          if unexpanded == "^^"
            value.upcase
          elsif unexpanded == "^"
            value.capitalize
          elsif unexpanded == ",,"
            value.downcase
          elsif unexpanded == ","
            value[0].downcase << value[1..-1]
          elsif unexpanded == "~~"
            value.swapcase
          elsif unexpanded == "~"
            value[0].swapcase << value[1..-1]
          elsif unexpanded.start_with?("%%")
            match = longest_match_r(unexpanded[2..-1], value) || ""
            value.slice(0, value.length - match.length)
          elsif unexpanded.start_with?("%")
            match = shortest_match_r(unexpanded[1..-1], value) || ""
            value.slice(0, value.length - match.length)
          elsif unexpanded.start_with?("##")
            match = longest_match(unexpanded[2..-1], value) || ""
            value.slice(match.length..-1)
          elsif unexpanded.start_with?("#")
            match = shortest_match(unexpanded[2..-1], value) || ""
            value.slice(match.length..-1)
          elsif unexpanded.start_with?("-")
            if value.nil?
              call(unexpanded[1..-1], env)
            else
              value
            end
          elsif unexpanded.start_with?(":-")
            if value.nil? or value.empty?
              call(unexpanded[1..-1], env)
            else
              value
            end
          elsif unexpanded.start_with?("+")
            if value.nil? or !value.empty?
              value
            else
              call(unexpanded[1..-1], env)
            end
          elsif unexpanded.start_with?(":+")
            if value.nil? or value.empty?
              value
            else
              call(unexpanded[2..-1], env)
            end
          elsif unexpanded.start_with?("?")
            raise KeyError if value.nil?
          elsif unexpanded.start_with?(":?")
            raise KeyError if value.nil? or value.empty?
          elsif unexpanded.start_with?("//")
          elsif unexpanded.start_with?("/#")
            value
          elsif unexpanded.start_with?("/%")
            value
          elsif unexpanded.start_with?(":")
            unexpanded =~ /:(\d+)(?::(\d))?/
            start, length = [$1, $2 || "1"].map(&:to_i)
            value.slice(start, length)
          else
            raise "don't know how to handle expansion `#{unexpanded}`"
            #value << unexpanded
          end
        end
      end
    end
  end
end
