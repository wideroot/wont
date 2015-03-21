module Wont


class Wambda < Instance
  def initialize source, path
    self.ruby_source = source
    self.path = path
  end
  
  def valid?
    super && ruby_source != '' && path != ''
  end

  def instance_path_chain
    [instance_filename, path.split('/').reverse]
  end

  def self.create_from_code filename, path = filename
    self.new(File.read(filename), path)
  end
end



def self.require_wambda path
  # Instance/Wambda/path/uid__version.json
  # TODO
end


end
