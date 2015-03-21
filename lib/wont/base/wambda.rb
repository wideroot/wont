module Wont


class Wambda < Instance
  def initialize source, wambda_path
    self.ruby_source = source
    self.wambda_path = wambda_path
  end
  
  def valid?
    super && ruby_source != '' && wambda_path != ''
  end

  def instance_path_chain
    [instance_filename, wambda_path.split('/').reverse]
  end

  def self.create_instance_from_rb file, wambda_path
    self.new(File.read(filename), wambda_path)
  end

  def self.load_wambda_base
  end
end



def self.require_wambda wambda_path
  # Instance/Wambda/path/uid__version.json
  # Instance/Wambda/path/uid__version.json
  # TODO
end


end
