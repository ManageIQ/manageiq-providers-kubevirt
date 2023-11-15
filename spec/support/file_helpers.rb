require 'recursive_open_struct'

module FileHelpers
  def unprocessed_object(file)
    RecursiveOpenStruct.new(unprocessed_hash(file), :recurse_over_arrays => true)
  end

  def unprocessed_hash(file)
    data = file_fixture(file).read
    YAML.safe_load(data, :permitted_classes => [Symbol])
  end
end
