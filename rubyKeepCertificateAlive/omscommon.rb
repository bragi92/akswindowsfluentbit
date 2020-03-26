module OMS
    class CaseSensitiveString < String
        def downcase
          self
        end
        def capitalize
          self
        end
        def to_s
          self
        end
    end

    class StrongTypedClass
        def self.strongtyped_accessor(name, type)
          # setter
          self.class_eval("def #{name}=(value);
          if !value.is_a? #{type} and !value.nil?
              raise ArgumentError, \"Invalid data type. #{name} should be type #{type}\"
          end
          @#{name}=value
          end")
          # getter
          self.class_eval("def #{name};@#{name};end")
        end
        
        def self.strongtyped_arch(name)
          # setter
          self.class_eval("def #{name}=(value);
          if (value != 'x64' && value != 'x86')
              raise ArgumentError, \"Invalid data for ProcessorArchitecture.\"
          end
          @#{name}=value
          end")
        end
    end
end