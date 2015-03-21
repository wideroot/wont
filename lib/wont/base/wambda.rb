module Wont


  class Wambda < Instance
    def initialize src = nil
      super(src)
    end

    def valid?
      super && ruby_source != '' && wambda_path != ''
    end

    def instance_head_chain
      [instance_filename] + wambda_path.split('/').reverse
    end


    def self.create_instance_from_rb filename, wambda_path
      name = File.basename(filename).chomp('.rb')
      ruby_code = File.read(filename)
      new({'wambda_path' => wambda_path, 'ruby_code' => ruby_code}.to_ii(name, Wont::VERSION))
    end
  end


end
