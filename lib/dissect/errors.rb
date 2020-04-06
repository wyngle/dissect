module Error

  class Standard < StandardError; end
  class NoMatches < Standard
    def initialize(msg = "{:error:'No matches'}")
      super
    end
  end

  class ConfigFileError < Standard
    def initialize(msg = "something's wrong with your config file options")
      super
    end
  end

  class NoData < Standard
    def initialize(msg = "can't dissect for nil or empty data")
      super
    end
  end

  class Encoded < Standard
    def initialize(msg = "can't dissect. data encoded in base64")
      super
    end
  end

  class StructureDataErr < Standard
    def initialize(msg = "unable to find specified structure data")
      super
    end
  end


end
