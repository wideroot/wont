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
    load_wambda_base
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


  def self.load_base_from_lib
    fail "Already initialized: #{@@path}" if initialized?
    require_relative('./base/instance.rb')
    require_relative('./base/wambda.rb')
    Dir["./base/**/*.rb"].each do |file|
      wambda_path = File.join('_base', File.basename(file))
      instance = Wambda.create_instance_from_rb(file, wambda_path)
      add(instance)
    end
    revision = `git rev-parse --verify HEAD`.strip
    commit("load_base_from_code #{pwd}, HEAD: #{revision}")
  end



private
  def self.load_wambda_base
    # TODO load instance, load wambda
    # require_wambda...
  end

  def self.apply_filter version, paths
    fail "Not implemented" if version != nil
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
