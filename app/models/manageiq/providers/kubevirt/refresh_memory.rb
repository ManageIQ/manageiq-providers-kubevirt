require 'json'
require 'set'

#
# This class remembers the pieces of that that need to be remembered in order to avoid processing
# twice notices received from Kubernetes watches.
#
# Current implementation stores the data in memory and there is no need to make it presistent
# since we run full refresh every time we start the worker and when watches expire.
#
class ManageIQ::Providers::Kubevirt::RefreshMemory
  #
  # Creates a new object to hold the refresh data for the manager with the given identifier.
  #
  def initialize
    # Initialize the hash that contains the last resource version for each kind of list. The keys of
    # this hash will be strings identifying the kind of object, for example `vminstances`. The values will
    # be the last `resource_version` that was obtained when listing that kind of object.
    @lists = {}

    # Initialize the set that contains the keys of the notices that have already been processed.
    @notices = Set.new
  end

  #
  # Returns `true` if there is no data.
  #
  # @return [Boolean] A boolean value indicating if there is no data.
  #
  def empty?
    @lists.empty? && @notices.empty?
  end

  #
  # Sets the last resource version that has been obtained when listing the given kind of object.
  #
  # @param kind [String] The kind of object, for example `vm_instances`.
  # @param version [String] The resource version.
  #
  def add_list_version(kind, version)
    kind = kind.to_s
    @lists[kind] = version
  end

  #
  # Returns the last resource version that was obtained when listing the given kind of object.
  #
  # @param kind [String] The kind of object, for example `vminstances`.
  # @return [String] The resource version.
  #
  def get_list_version(kind)
    kind = kind.to_s
    @lists[kind]
  end

  #
  # Adds a notice that has been already processed.
  #
  # @param notice [Object] The notice object.
  #
  def add_notice(notice)
    key = notice_key(notice)
    unless @notices.include?(key)
      @notices.add(key)
    end
  end

  #
  # Checks if this data contains the given notice.
  #
  # @param notice [Object] The notice to check.
  # @return [boolean] A boolean value indicating if this data contains the given notice.
  #
  def contains_notice?(notice)
    key = notice_key(notice)
    @notices.include?(key)
  end

  private

  #
  # Names for JSON attributes:
  #
  LISTS = 'lists'.freeze
  NOTICES = 'notices'.freeze

  #
  # Calculates the key that will be used to store a notice.
  #
  def notice_key(notice)
    "#{notice.kind}:#{notice.resource_version}"
  end
end
