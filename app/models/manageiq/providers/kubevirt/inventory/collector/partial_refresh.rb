class ManageIQ::Providers::Kubevirt::Inventory::Collector::PartialRefresh < ManageIQ::Providers::Kubevirt::Inventory::Collector
  def initialize(manager, notices)
    super(manager, nil)

    # The notices returned by the Kubernetes API contain always the complete representation of the object, so it isn't
    # necessary to process all of them, only the last one for each object.
    notices.reverse!
    notices.uniq!(&:uid)
    notices.reverse!

    @nodes          = notices_of_kind(notices, 'Node')
    @vms            = notices_of_kind(notices, 'VirtualMachine')
    @vm_instances   = notices_of_kind(notices, 'VirtualMachineInstance')
    @instance_types = notices_of_kind(notices, 'VirtualMachineClusterInstanceType')
  end

  private

  #
  # Returns the notices that contain objects of the given kind.
  #
  # @param notices [Array] An array of notices.
  # @param kind [String] The kind of object, for example `Node`.
  # @return [Array] An array containing the notices that have the given kind.
  #
  def notices_of_kind(notices, kind)
    notices.select { |notice| notice.object.kind == kind }
  end
end
