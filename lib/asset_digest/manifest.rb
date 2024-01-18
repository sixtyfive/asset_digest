require "pathname"
require "json"

module AssetDigest
  class Manifest
    def initialize(source:, destination:)
      @source = Pathname.new(source)
      @destination = Pathname.new(destination)
      @manifest = {}
    end

    def add(source_path, destination_path)
      relative_source_path = source_path.relative_path_from(source)
      relative_destination_path = destination_path.relative_path_from(destination)

      @manifest[relative_source_path.to_s] = relative_destination_path.to_s
      true
    end

    def to_h
      @manifest
    end

    def write(destination)
      destination.write(@manifest.to_json)
    end

    def write_file(path)
      File.open(path, "w") do |f|
        write(f)
      end
    end

    private

    attr_accessor :source
    attr_accessor :destination
  end
end
