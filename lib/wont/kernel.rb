require 'shellwords'


module Wont

  KERNEL = %(instance space basic_literals entity)

  def self.initialize path = nil, pull: false
    fail "Already initialized: #{@@path}" if @@path != nil
    if !path
      path = `git rev-parse --show-toplevel`
      path = nil if path == ""
      if path
        path = File.join(path, 'ontology_data')
      end
    end
    if !path
      fail "Invalid path" if path == ""
    end
    @@path = path
    @@commands = []
    @@version = nil  # TODO add version parameter, and implement it
    `cd #{@@path} ; git pull` if pull
    KERNEL.each { |symbol| get_wambda_symbol(symbol) }
    true
  end

  def self.add ir_instance
    @@commands << ['add_instance', ir_instance]
  end

  def self.commit message = nil
    @@commands.each { |command| perform_command(command) }
    `cd #{data_path} ; git commit -m #{Shellwords.escape(message)}`
  end

  def self.new_uid
    SecureRandom.uuid
  end

  def self.get_instance uid, version = nil
    paths = `find #{data_path} -type f -name #{uid}_*' -print0`.split("\u0000")
    paths.map do |path|
      _, _, version = path.rpartition('_')
      version = version.split
      version << path
    end
    path = apply_filter(version, paths)
    JSON.parse(File.read(path))
  end

  def self.get_wambda_symbol symbol
    fail "Unexpected #{symbol.class}: #{symbol}" unless symbol.is_a?(Symbol)
    wobjs = get_symbol(symbol)
    return wobj if wobj
    paths = Dir["#{data_path}/**/#{symbol}/_#{symbol.to_s.underscore}/*-*.json"]
    uids = Set
    paths.map do |path|
      uid, _, version = File.basename(path).rpartition('-')
      version = version.split('.')
      version << path
      uids.add(uid)
    end
    path = apply_filter(@@version, paths)
    instance = JSON.parse(File.read(path))
    filename = wambda_path(symbol)
    mkdir_p(File.dirname(filename))
    File.open(filename, File::WRONLY|File::TRUNC|File::CREAT, 0644) do |file|
      file.write(instance['accessors']['ruby_code'])
    end
    require_relative(filename)
    get_symbol(symbol)
  end

  module Helper
    def self.from_ruby_to_instance file
      # TODO
    end
  end


private:
  def self.get_symbol symbol
    begin
      # TODO allow methods also as wambda symbols
      Wambda.const_get(symbol)
    rescue
      nil
    end
  end

  def self.apply_filter version, paths
    fail "Not implemented" if version != nil
    paths.sort.last
  end

  def self.wambda_path symbol
    File.join(wambda_dir, symbol + '.rb')
  end

  def self.wambda_dir
    File.join(@@path, ".wambda-#{version}")
  end

  def self.instance_path path
    File.join(@@path, path)
  end

  def self.perform_command command
    action, operand = command
    case action
    when 'add_instance'
      filename = instance_path(@@path, ir_instance[:path])
      mkdir_p(File.dirname(filename))
      File.open(filename, File::WRONLY|File::TRUNC|File::CREAT, 0644) do |file|
        file.write(obj.to_json)
      end
    else
      fail "Unknown action #{action}: #{command}"
    end
  end

end
