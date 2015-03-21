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

  def self.initialize path = nil, pull: false, load_base: true
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
    load_wambda_base if load_base
    true
  end


  def self.add ir_instance
    fail "not init" unless initialized?
    @@commands << [:add_instance, ir_instance]
  end

  def self.commit message = nil
    fail "not init" unless initialized?
    warn "commit !"
    @@commands.each { |command| perform_command(command) }
    `cd #{data_dir} ; git commit -m #{Shellwords.escape(message)}`
    warn "commit: #{message}"
  end


  def self.get_instance uid, version = nil
    fail "not init" unless initialized?
    json = get_instance_json(uid, version)
    frame = const_get(json['frame'].to_sym)
    frame.new(json)
  end

  def self.version
    fail "not init" unless initialized?
    @@version
  end


  def self.new_uid
    SecureRandom.uuid
  end

  def self.get_wambda_id_from_string identifier
    if  ( identifier.is_a?(String) &&
          identifier.length < 256 &&
          !identifier.include?('__') &&
          identifier =~ /^[A-Za-z][A-Za-z0-9_]*$/
        )
      identifier
    else
      nil
    end
  end


  def self.create_instances_from_baselib
    fail "not init" unless initialized?
    dir = instance_path(File.join('Instance', 'Wambda', 'base'))
    fail "`#{dir}' already exists" if File.exists?(dir)
    basedir = File.join(File.dirname(__FILE__), 'base')
    %w(instance wambda space basic_literal).each do |file|
      relative_path = File.join(basedir, file + '.rb')
      warn "requiring #{file}: #{relative_path}"
      require_relative(relative_path)
    end
    Dir["#{basedir}/**/*.rb"].each do |file|
      # TODO improve this...
      wambda_path = File.join('base', File.basename(file))
      instance = Wambda.create_instance_from_rb(file, wambda_path)
      instance.save!
    end
    revision = `git rev-parse --verify HEAD`.strip
    commit("load_base_from_code #{__FILE__}, HEAD: #{revision}")
  end



private

  def self.apply_filter version, paths
    fail "Not implemented" if paths.size != 1
    paths.sort.last
  end


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
      filename = instance_path(ir_instance['path'])
      warn "path: #{File.dirname(filename)}"
      write_file(filename, JSON.pretty_generate(ir_instance))
      `git add #{filename}`
      warn "added #{ir_instance['name']} #{ir_instance['version']} at #{filename}"
    else
      fail "Unknown action #{action}: #{command}"
    end
  end


  def self.get_instance_json uid, version = nil
    fail "not init" unless initialized?
    #paths = `find #{data_dir} -type f -name #{uid}_*' -print0`.split("\u0000")
    paths = Dir["#{data_dir}/**/#{uid}_*.json"]
    warn "instances: #{paths}"
    paths.map do |path|
      _, _, version = path.rpartition('_')
      version = version.split
      version << path
    end
    path = apply_filter(version, paths)
    path ? JSON.parse(File.read(path)) : nil
  end


private
  def self.load_wambda_base
    %w(instance wambda).each do |wambda|
      wambda_path = "base/#{wambda}.rb"
      warn "load_wambda_base #{wambda_path}"
      path = wambda_file_path(wambda_path)
      if !File.exists?(path)
        uid = get_uid_wambda_path(wambda_path)
        instance = get_instance_json(uid, version)
        warn instance.inspect
        if instance['frame'] != 'Wambda'
          fail "unexpected instance with frame #{instance['frame']}"
        end
        write_wambda_file(path, instance['accessors']['ruby_code'])
      end
      require_relative(path)
    end
    Dir["#{data_wambda_dir}/base/**/*.rb"].each do |wambda|
      wambda_path = wambda[data_wambda_dir.size + 1 .. -1]
      require_wambda(wambda_path)
    end
  end


  def self.data_wambda_dir
    File.join(data_dir, 'Instance', 'Wambda')
  end

  def self.wambda_dir
    File.join(data_dir, ".wambda__cache__#{version}")
  end

  def self.wambda_file_path path
    File.join(wambda_dir, path)
  end


  def self.get_uid_wambda_path wambda_path
    uids = Set.new
    Dir["#{data_wambda_dir}/#{wambda_path}/*__*.json"].each do |path|
      file = File.basename(path)
      uids.add(file.rpartition('_')[0])
    end
    if uids.size > 1
      fail "found instances #{uids.to_a.inspect} for wambda_path `#{wambda_path}'"
    elsif uids.empty?
      raise LoadError "cannot load such wambda file -- #{wambda_path}"
    end
    uids.first
  end


  def self.require_wambda wambda_path
    wambda_path += '.rb' unless wambda_path.end_with?('.rb')
    path = wambda_file_path(wambda_path)
    warn "require #{wambda_path} -- #{path}"
    begin
      require_relative(path)
    rescue LoadError => ex
      if !File.exists?(path)
        uid = get_uid_wambda_path(wambda_path)
        instance = get_instance(uid, version)
        warn instance.inspect
        if instance.frame != Wambda
          fail "unexpected instance with frame #{instance.frame}"
        end
        write_wambda_file(path, instance.ruby_code)
      else
        raise LoadError "cannot load such wambda file -- #{wambda_path}"
      end
    end
    require_relative(path)
  end

  def self.write_wambda_file filename, ruby_code
    write_file(filename, ruby_code)
  end


private
  def self.write_file(filename, string)
    FileUtils::mkdir_p(File.dirname(filename))
    File.open(filename, File::WRONLY|File::TRUNC|File::CREAT, 0644) do |file|
      file.write(string)
    end
  end
end
