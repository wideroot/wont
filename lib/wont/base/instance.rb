module Wont


class Instance
  # TODO add this two class methods into frame
  # (now load_base_from_code uses path from Instance before loading frame...,
  # (however, something like class Instance; end require_module, will do the trick)
  def self.frame
    Frame
    # note we assume that at some point require_wambda will be called before
    # this method is called
  end
  def self.superframe
    self == Instance ? nil : superclass
  end
  def frame
    self.class
  end


  def initialize src, is_new: false
    if src == nil
      src = {
        'uid'       => nil,
        'version'   => "0.0.0",
        'name'      => nil,
        'accessors' => {},
      }
    end
    # TODO add an extend mechanism
    # src.extended [[method|mixin, uid]
    # @_method_aliases {}

    # index fields
    @uid = src['uid']
    @version = src['version'].split('.')
    @name = src['name']

    # @accessors[field] = value s.t. value.to_w? == value
    @accessors = src['accessors']

    # internal variables
    @uid = nil if is_new
    @updated = @new = uid == nil
    warn inspect
  end


  def uid; @uid; end
  def version; @version.join('.'); end
  def name; @name; end
  def name= name; @name = name; end
  def major; @version[0]; end
  def minor; @version[1]; end
  def teeny; @version[2]; end

  def inspect
    char = '*' if updated?
    char = 'N' if new?
    "<#{char}#{uid ? uid : 'nil'}_#{version} : #{frame}> #{@accessors}"
  end


  def new_major!; @version[0] += 1; end
  def new_minor!; @version[1] += 1; end


  def new?      ; @new; end
  def updated?  ; @updated; end


  def valid?
    # TODO names should be more restricted
    # typecheck v with k...
    name != nil && name.size > 0 && @accessors.all? { |_, v| v.valid? }
  end

  def valid!
    raise "invalid instance" unless valid?
  end


  def clone
    # TODO improve dup/clone
    cloned = super
    cloned.reset_uid!
  end

  def dup
    clone
  end


  def save! recursive = false
    if @updated
      valid!
      new_teeny
      assign_uid!(recursive: true)
      @accessors.map { |k,e| e.save!(recursive: recursive) } if recursive
      Wont::add(internal_representation)
      @updated = @new = false
    end
  end


  def method_missing symbol, *args, &block
    s = symbol.to_s
    #warn "method_missing: #{s}"

    # *__set
    wid = accessor_symbol_setter(s)
    if wid
      if args.size != 1
        raise ArgumentError, "wrong number of arguments (#{args.size} for 1)"
      end
      @updated = true
      return @accessors[wid] = args.first
    end

    # *__get
    wid = accessor_symbol_getter(s)
    if wid && args.empty?
      return @accessors[wid]
    end

    super
  end

  def respond_to? symbol, included_all = false
    # TODO
    super
  end



  def to_w; self; end



protected
  def new_teeny!; @version[2] += 1; end


  def internal_value
    {'name' => name, 'uid' => uid, 'version' => version}
  end

  def attr_internal_value
    InternalReference.new(self).attr_internal_value
  end

  def internal_representation
    s = frame.to_s
    fail "#{self} frame is not Wont::..." unless s.start_with? 'Wont::'
    s = s['Wont::'.size .. -1]
    i = internal_value
    i['path']       = instance_path
    i['frame']      = s
    i['accessors']  = Hash[@accessors.map { |k,e| [k, e.attr_internal_value] }]
    i
  end



  def instance_filename
    "#{uid}__#{version}.json"
  end

  def instance_head_chain
    [instance_filename, name]
  end

  def instance_tail_chain
    chain = [frame]
    while chain.last.superframe
      chain << chain.last.superframe
    end
    chain
  end

  def instance_path_chain
    instance_head_chain + instance_tail_chain
  end

  def instance_path
    chain = instance_path_chain
    File.join(chain.reverse.map { |i| i.to_s.rpartition(/::/).last })
  end


  def reset_uid!
    @uid = nil
    @updated = @new = true
  end

  def assign_uid! recursive = true
    if recursive
      @accessors.each { |k,e| e.assign_uid!(recursive: recursive) }
    end
    @uid = Wont::new_uid unless @uid
  end



private
  def accessors_instances
    @accessors.select { |attr| attr.is_a? Instance }
  end

  def accessor_symbol_getter string
    string.extend(Chomps)
    #puts "asg #{string}: #{string.chomps('__get', '')}"
    Wont.get_wambda_id_from_string(string.chomps('__get', ''))
  end

  def accessor_symbol_setter string
    string.extend(Chomps)
    #puts "ass #{string}: #{string.chomps('__set', '=')}"
    Wont.get_wambda_id_from_string(string.chomps('__set', '='))
  end

  module Chomps
    # \pre: postfix are ordered by desc length
    def chomps(*postfixs)
      postfixs.each do |postfix|
        s = chomp(postfix)
        return s if s.size != size || postfix.empty?
      end
      nil
    end
  end
end


  def self.internal_representation_instance name: nil, version: nil, accessors: {}
    version = "0.0.0" unless version
    { 'uid'       => nil,
      'name'      => name,
      'version'   => version,
      'accessors' => accessors,
    }
  end


end


class Hash
  def to_ii name = nil, version = nil
    Wont::internal_representation_instance(
      name:       name,
      version:    version,
      accessors:  self,
    )
  end
end

# TODO 
# create frames usin an object as prototype
# include, extend, class methods, instance methods, singleton methods...
# static type...
