# TODO check status


require 'shellwords'
require 'securerandom'
require 'fileutils'
require 'active_support/inflector'
require 'json'


module Wont
  @@path = nil


  def self.initialized?
    @@path != nil
  end

  def self.initialize path = nil, pull: false, do_not_load_kernel: true
    fail "Already initialized: #{@@path}" if initialized?
    if !path
      path = `git rev-parse --show-toplevel`.strip
    end
    path = nil if path == ""
    if !path
      fail "Invalid path" if path == ""
    end
    @@path = path
    @@commands = []
    @@version = nil  # TODO add version parameter, and implement it
    `cd #{@@path} ; git pull` if pull
    warn "initialized: #{@@path}"
    true
  end


  def self.add ir_instance
    fail "not init" unless initialized?
    @@commands << [:add_instance, ir_instance]
  end

  def self.commit message = nil
    fail "not init" unless initialized?
    @@commands.each { |command| perform_command(command) }
    `cd #{data_dir} ; git commit -m #{Shellwords.escape(message)}`
    warn "commit: #{message}"
  end

  def self.new_uid
    fail "not init" unless initialized?
    SecureRandom.uuid
  end


  def self.get_instance uid, version = nil
    fail "not init" unless initialized?
    paths = `find #{data_dir} -type f -name #{uid}_*' -print0`.split("\u0000")
    warn "instances: #{paths}"
    paths.map do |path|
      _, _, version = path.rpartition('_')
      version = version.split
      version << path
    end
    path = apply_filter(version, paths)
    fail "not found instance `#{uid}'" unless path
    JSON.parse(File.read(path))
  end

=begin
  def self.get_wambda_symbol symbol
    fail "not init" unless initialized?
    wobj = get_symbol(symbol)
    return wobj if wobj
    require_wambda(symbol.to_s.underscore)
    get_symbol(symbol)
  end
=end


  # helpers
  def self.get_wambda_id_from_string identifier
    fail "not init" unless initialized?
    if  ( identifier.is_a?(String)
          identifier.length < 256 &&
          identifier[/__/] &&
          identifier =~ /^[A-Za-z][A-Za-z0-9_]*$/
        )
      identifier
    else
      nil
    end
  end


  def self.load_base_from_code
=begin
    # TODO require_relative instance
    # TODO require_relative wambda
    # TODO forall...
    fail "not init" unless initialized?
    si = nil
    begin
      si = get_wambda_symbol(:Instance)
    rescue => ex # TODO rescue only when Instance is not found ...
      warn "got #{ex}"
      warn ex.backtrace.join("\n")
    end
    fail "instance exists" if si
    basedir = File.join(File.dirname(__FILE__), 'base')
    instance = File.join(basedir, 'instance.rb')
    uid = new_uid
    version = [0,0,0].join(".")
    filename = "#{uid}__#{version}.json"
    path = File.join("Instance", "_instance", filename)
    i = { path:       path,
          name:       'instance',
          uid:        uid,
          version:    '0.0.0',
          frame:      :Frame,
          accessors:  { ruby_code: File.read(instance) },
    }
    perform_command([:add_instance, i])
    get_symbol(:Instance)
    Dir["#{base_dir}/**/*.rb"].each do |basefile|
      # TODO !!!
    end
    true
=end
  end

  # TODO capture NameError: uninitialized constant...


private
=begin
  def self.load_wambda_symbol symbol
    fail "Unexpected #{symbol.class}: #{symbol}" unless symbol.is_a?(Symbol)
    path = symbol.to_s.split('::')[1..-1]
    paths = Dir["#{data_dir}/**/#{symbol}/_#{symbol.to_s.underscore}/*__*.json"]
    warn "symbol: #{paths}"
    uids = Set.new
    paths.map do |path|
      uid, _, version = File.basename(path).rpartition('__')
      version = version.split('.')
      version << path
      uids.add(uid)
    end
    fail "more than one instance candidate: #{uids.to_a}" if uids.size > 1
    path = apply_filter(@@version, paths)
    return false unless path  # "not found wambda symbol `#{symbol}'"
    instance = JSON.parse(File.read(path))
    filename = wambda_path(symbol)
    FileUtils::mkdir_p(File.dirname(filename))
    File.open(filename, File::WRONLY|File::TRUNC|File::CREAT, 0644) do |file|
      transform_ruby_code(file.write(instance['accessors']['ruby_code']))
    end
    fail "require_relative #{filename} returned false" if !require_relative(filename)
    true
  end

  def self.get_symbol symbol
    # TODO allow methods also
    begin
      self.const_get(symbol)
    rescue
      nil
    end
  end
=end


  def self.apply_filter version, paths
    fail "Not implemented" if version != nil
    paths.sort.last
  end

=begin
  def self.wambda_path symbol
    File.join(wambda_dir, symbol.to_s + '.rb')
  end

  def self.wambda_dir
    File.join(data_dir, ".wambda-symbol-cache__#{@@version}")
  end

  def self.transform_ruby_code ruby_code
    ruby_code
  end

=end

  def self.data_dir
    File.join(@@path, "ontology_data")
  end

  def self.instance_path path
    File.join(data_dir, path)
  end


  def self.perform_command command
    action, operand = command
    case action
    when :add_instance
      ir_instance = operand
      filename = instance_path(ir_instance[:path])
      warn "path: #{File.dirname(filename)}"
      FileUtils::mkdir_p(File.dirname(filename))
      File.open(filename, File::WRONLY|File::TRUNC|File::CREAT, 0644) do |file|
        file.write(JSON.pretty_generate(ir_instance))
      end
      `git add #{filename}`
      warn "added #{ir_instance[:name]}__#{ir_instance[:version]} at #{filename}"
    else
      fail "Unknown action #{action}: #{command}"
    end
  end

end
