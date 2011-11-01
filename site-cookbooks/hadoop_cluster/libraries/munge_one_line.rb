module MungeOneLine

  #
  # @param [String] name       - name for the resource invocation
  # @param [String] filename   - the file to modify (in-place)
  # @param [String] old_line   - the string to replace
  # @param [String] new_line   - the string to insert in its place
  # @param [String] shibboleth - a simple foolproof string that should be
  #    present after this works
  #
  def munge_one_line(name, filename, old_line, new_line, shibboleth)
    execute name do
      command %Q{sed -i -e 's|#{old_line}|#{new_line}| ' '#{filename}'}
      not_if  %Q{grep -e -q '#{shibboleth}' '#{filename}'}
      only_if{ File.exists?(filename) }
      yield if block_given?
    end
  end
  
end

class Chef::Recipe
  include MungeOneLine
end


