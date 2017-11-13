module Dotenv
  # This class inherits from Hash and represents the environment into which
  # Dotenv will load key value pairs from a file.
  class Environment < Hash
    attr_reader :filename

    def initialize(filename)
      super
      self.default_proc = lambda { |_, k| abort "WHEEEEE" ; ENV[k] }
      @filename = filename
      load
    end

    def load
      update Parser.call(read)
    end

    def read
      File.open(@filename, "rb:bom|utf-8", &:read)
    end

    def apply
      each { |k, v| ENV[k] ||= v }
    end

    def apply!
      each { |k, v| ENV[k] = v }
    end

    def fetch(*args, &block)
      super(*args, &block)
    rescue KeyError
      ENV[args.first]
    end
  end
end
