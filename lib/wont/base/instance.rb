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


  def initialize src = nil
    @new = @updated = true
    if src == nil
      src = {
        uid:        nil,
        version:    "0.0.0",
        name:       nil,
        accessors:  {},
      }
    end
    # TODO add an extend mechanism
    # src.extended [[method|mixin, uid]
    # @_method_aliases {}

    # index fields
    @uid = src[:uid]
    @version = src[:version].split('.')
    @name = src[:name]

    # @accessors[field] = value s.t. value.to_w? == value
    @accessors = src[:accessors]
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


  def new       ; @new; end
  def updated?  ; @updated; end


  def valid?
    # TODO names should be more restricted
    name != nil && name.size > 0 && @accessors.all { |i| i.valid? }
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
    warn s

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
    {name: name, uid: uid, version: version}
  end

  def attr_internal_value
    InternalReference.new(self).attr_internal_value
  end

  def internal_representation
    i = internal_value
    i[:path]      = instance_path
    i[:frame]     = frame
    i[:accessors] = Hash[@accessors.map { |k,e| [k, e.attr_internal_value] }]
  end

  def instance_path

  def instance_filename
    "#{uid}__#{version}.json"
  end
  def instance_path_chain
    [instance_filename, name] + instance_frame_chain
  end
  def instance_frame_chain
    chain = [frame]
    while chain.last.superframe
      chain << chain.last.superframe
    end
    chain
  end
  def instance_paths
    chain = instance_path_chain
    File.join(chain.reverse.map { |i| i.to_s.rpartition('::').last })
  end


  def reset_uid!
    @uid = nil
  end

  def assign_uid! recursive = true
    if recursive
      accessors.each { |k,e| e.assign_uid!(recursive: recursive) }
    end
    @uid = Wont::new_uid unless @uid
  end



private
  def accessors_instances
    @accessors.select { |attr| attr.is_a? Instance }
  end

  def accessor_symbol_getter string
    string.extend(Chomps)
    Wont.get_wambda_id_from_string(string.chomps('__get', ''))
  end

  def accessor_symbol_setter string
    string.extend(Chomps)
    Wont.get_wambda_id_from_string(string.chomps('__set', '='))
  end

  module Chomps
    # \pre: postfix are ordered by desc length
    def chomps(*postfixs)
      postfixs.each do |postfix|
        return true if postfix.empty?
        s = chomp(postfix)
        return s if s.size != size
      end
      nil
    end
  end
end


end
