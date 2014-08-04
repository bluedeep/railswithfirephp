module ActiveRecord
  class Base
    ModelLog = []
    def fb msg, label=nil
      ModelLog << {msg: msg, label:label}
    end
  end
end
