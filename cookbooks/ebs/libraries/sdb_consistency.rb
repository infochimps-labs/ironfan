# Modifies RightAws in order to add support for Conditional Puts.
# Also makes modifications to allow the replace paramater to be an array of attributes
# to replace, rather than just a simple boolean. This allows mixed replace/non-replace put's
# to be made in a single call.
# Also modifies delete_attributes so you can either pass an array to delete_attributes
# or pass a hash, with the value set to ':all'. So, eg, the following are equivalent:
#   delete_attributes('domain', 'item', ['a', 'b'])
#   delete_attributes('domain', 'item', {'a' => :all 'b' => :all})

module RightAws

  class SdbInterface < RightAwsBase

    # Override, in order to support consistency.
    API_VERSION = '2009-04-15'

    # Prepare attributes for putting or deleting.
    # (used by put_attributes, delete_attributes and batch_put_attributes)
    def pack_attributes(attributes, replace = false, expected_attributes = {}) #:nodoc:
      result = {}
      if attributes
        idx = 0
        skip_values = attributes.is_a?(Array)
        attributes.each do |attribute, values|
          # set replacement attribute
          if replace == true or (replace.kind_of?(Enumerable) and replace.include?(attribute))
            result["Attribute.#{idx}.Replace"] = 'true'
          end

          # set expected attribute
          if expected_attributes.include?(attribute)
            result["Expected.#{idx}.Name"] = attribute
            if expected_attributes[attribute].nil?
              result["Expected.#{idx}.Exists"] = 'false'
            else
              result["Expected.#{idx}.Value"] = expected_attributes[attribute]
            end
          end

          # pack Name/Value
          values = [nil] if values.nil?
          Array(values).each do |value|
            result["Attribute.#{idx}.Name"]  = attribute
            unless skip_values or values == :all
              result["Attribute.#{idx}.Value"] = ruby_to_sdb(value)
            end
            idx += 1
          end
        end
      end
      result
    end

    def put_attributes(domain_name, item_name, attributes, replace = false, expected_attributes = {})
      params = { 'DomainName' => domain_name,
        'ItemName'   => item_name }.merge(pack_attributes(attributes, replace, expected_attributes))
      link = generate_request("PutAttributes", params)
      request_info( link, QSdbSimpleParser.new )
    rescue Exception
      on_exception
    end

    def delete_attributes(domain_name, item_name, attributes = nil, expected_attributes = {})
      params = { 'DomainName' => domain_name,
        'ItemName'   => item_name }.merge(pack_attributes(attributes, false, expected_attributes))
      link = generate_request("DeleteAttributes", params)
      request_info( link, QSdbSimpleParser.new )
    rescue Exception
      on_exception
    end

  end
end
