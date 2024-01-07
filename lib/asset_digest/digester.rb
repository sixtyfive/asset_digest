require "digest"
require "fileutils"
require "pathname"

module AssetDigest
  class Manifest
    def initialize(source:, destination:)
      @source = source
      @destination = destination
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

    private

    attr_accessor :source
    attr_accessor :destination
  end

  class SourcePath
    def initialize(source)
      @source = Pathname.new(source)
    end

    def each_asset
      @source.glob("**/*").each do |source|
        next if source.directory?

        yield source
      end
    end
  end

  class Digester
    attr_accessor :source
    attr_accessor :destination
    attr_accessor :manifest
    attr_accessor :manifest_path
    attr_accessor :algorithm

    def initialize(source:, destination:, manifest_path:, algorithm: Digest::SHA1)
      @source = source
      @destination = destination
      @manifest_path = manifest_path
      @algorithm = algorithm
      @manifest = Manifest.new(source: source, destination: destination)
    end

    def digest_all
      SourcePath.new(source).each_asset do |source_path|
        destination_path = generate_destination_path(source, source_path)
        ensure_folder_exists(destination_path)
        manifest.add(source_path, destination_path)
        FileUtils.cp(source_path, destination_path)
      end
    end

    private

    def generate_digest(source)
      algorithm.hexdigest(source.read).slice(0, 10)
    end

    def generate_destination_path(source, source_path)
      sha = generate_digest(source_path)
      ext = source_path.extname
      filename = source_path.relative_path_from(source).to_s.chomp(ext)

      output = "#{filename}-#{sha}#{ext}"
      Pathname.new(destination).join(output)
    end

    def ensure_folder_exists(destination_path)
      FileUtils.mkdir_p(destination_path.dirname)
    end
  end
end
