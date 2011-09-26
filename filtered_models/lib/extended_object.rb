class Object
  class << self

    @@accessors = []
    @@setters = []
    @@getters = []



    alias :attr_accessor_old :attr_accessor
    def attr_accessor(*methname)

	  methname.each { |m|
		@@accessors << m	
	  }

      attr_accessor_old *methname
    end

    alias :attr_writer_old :attr_writer

    def attr_writer(*methname)
	  methname.each { |m|
	  	@@setters << m 
	  }

      attr_writer_old *methname
    end

    alias :attr_reader_old :attr_reader

    def attr_reader(*methname)
      
	  methname.each { |m|
	  	@@getters << m
	  }

      attr_reader_old *methname
    end

  end
end
