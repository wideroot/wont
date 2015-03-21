require_relative './instance.rb'

module Wont
  i = Instance.new
  i.name = 'yo'
  puts i.instance_path
end
  i = Wont::Instance.new
  i.name = 'yo'
  puts i.version
  puts i.instance_path
