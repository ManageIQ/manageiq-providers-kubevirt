#
# This is the base class for all the rest of the parsers. It contains the methods that will be
# shared by the full and targeted refresh parsers.
#
class ManageIQ::Providers::Kubevirt::Inventory::Parser < ManageIQ::Providers::Inventory::Parser
  include Vmdb::Logging

  protected

  #
  # The identifier of the built-in cluster:
  #
  CLUSTER_ID = '0'.freeze

  OS_LABEL_SYMBOL = :'kubevirt.io/os'

  attr_reader :cluster_collection
  attr_reader :host_collection
  attr_reader :host_hw_collection
  attr_reader :hw_collection
  attr_reader :network_collection
  attr_reader :os_collection
  attr_reader :template_collection
  attr_reader :vm_collection
  attr_reader :vm_os_collection
  attr_reader :disk_collection
  attr_reader :flavor_collection

  def add_builtin_clusters
    cluster_object = cluster_collection.find_or_build(CLUSTER_ID)
    cluster_object.ems_ref = CLUSTER_ID
    cluster_object.name = collector.manager.name
    cluster_object.uid_ems = CLUSTER_ID
  end

  def process_nodes(objects)
    objects.each do |object|
      process_node(object)
    end
  end

  def process_node(object)
    # Get the basic information:
    uid = object.metadata.uid
    name = object.metadata.name

    addresses = object.status.addresses.index_by(&:type)
    hostname  = addresses["Hostname"]&.address
    ipaddress = addresses["InternalIP"]&.address

    # Add the inventory object for the host:
    host_object = host_collection.find_or_build(uid)
    host_object.connection_state = 'connected'
    host_object.ems_cluster = cluster_collection.lazy_find(CLUSTER_ID)
    host_object.ems_ref = uid
    host_object.hostname = hostname
    host_object.ipaddress = ipaddress
    host_object.name = name
    host_object.uid_ems = uid

    node_info = object.status.nodeInfo

    # Add the inventory object for the operating system details:
    os_object = os_collection.find_or_build(host_object)
    os_object.name = hostname
    os_object.product_name = node_info.osImage
    os_object.product_type = node_info.operatingSystem
    os_object.version = node_info.kernelVersion

    hw_object = host_hw_collection.find_or_build(host_object)

    memory = object.status&.capacity&.memory
    memory &&= begin
      memory.iec_60027_2_to_i
    rescue
      memory.decimal_si_to_f
    end

    hw_object.memory_mb = (memory.to_f / 1.megabyte).round if memory
    hw_object.cpu_total_cores = object.status&.capacity&.cpu
  end

  def process_instance_types(objects)
    objects.each { |obj| process_instance_type(obj) }
  end

  def process_instance_type(object)
    cpu      = object.spec.cpu&.guest
    memory   = object.spec.memory&.guest
    memory &&= parse_quantity(memory) / 1.megabyte.to_f

    flavor_collection.build(
      :name            => object.metadata.name,
      :ems_ref         => object.metadata.uid,
      :cpu_total_cores => cpu,
      :memory          => memory
    )
  end

  def process_vms(objects)
    objects.each do |object|
      process_vm(object)
    end
  end

  def process_vm(object)
    # Process the domain:
    spec          = object.spec.template.spec
    domain        = spec.domain
    instance_type = object.spec.instancetype&.name

    vm_object = process_domain(object.metadata.namespace, domain.resources&.requests&.memory, domain.cpu, object.metadata.uid, object.metadata.name)

    # Add the inventory objects for the disks:
    hw_object = hw_collection.find_or_build(vm_object)
    process_disks(hw_object, domain, object.metadata.namespace, spec.volumes)

    # Add the inventory object for the OperatingSystem
    process_os(vm_object, object.metadata.labels, object.metadata.annotations)

    # The power status is initially off, it will be set to on later if the virtual machine instance exists:
    vm_object.raw_power_state = 'Succeeded'
    vm_object.flavor = flavor_collection.lazy_find({:name => instance_type}, :ref => :by_name) if instance_type
  end

  def process_vm_instances(objects)
    objects.each do |object|
      process_vm_instance(object)
    end
  end

  def process_vm_instance(object)
    # Get the basic information:
    uid = object.metadata.uid
    name = object.metadata.name

    # Get the identifier of the virtual machine from the owner reference:
    owner_references = object.metadata.ownerReferences&.first
    if owner_references&.name
      # seems like valid use case for now
      uid  = owner_references.uid
      name = owner_references.name
    end

    # Process the domain:
    vm_object = process_domain(object.metadata.namespace, object.spec.domain.memory&.guest, object.spec.domain.cpu, uid, name)

    # Add the inventory objects for the disks:
    hw_object = hw_collection.find_or_build(vm_object)
    process_disks(hw_object, object.spec.domain, object.metadata.namespace, object.spec.volumes, object.status.volumeStatus)

    process_status(vm_object, object.status.interfaces, object.status.nodeName)

    vm_object.host = host_collection.lazy_find(object.status.nodeName, :ref => :by_name)

    vm_object.raw_power_state = object.status.phase
  end

  def process_domain(namespace, memory, cpu, uid, name)
    # Create the inventory object for the virtual machine:
    vm_object = vm_collection.find_or_build(uid)
    vm_object.connection_state = 'connected'
    vm_object.ems_ref = uid
    vm_object.name = name
    vm_object.storage = nil
    vm_object.storages = []
    vm_object.template = false
    vm_object.uid_ems = uid
    vm_object.location = namespace

    cpu_sockets          = cpu&.sockets || 1
    cpu_cores_per_socket = cpu&.cores   || 1
    cpu_threads_per_core = cpu&.threads || 1
    cpu_total_cores      = cpu_sockets * cpu_cores_per_socket * cpu_threads_per_core

    # Create the inventory object for the hardware:
    hw_object = hw_collection.find_or_build(vm_object)
    hw_object.memory_mb            = parse_quantity(memory) / 1.megabyte.to_f if memory
    hw_object.cpu_sockets          = cpu_sockets
    hw_object.cpu_cores_per_socket = cpu_cores_per_socket
    hw_object.cpu_total_cores      = cpu_total_cores

    # Return the created inventory object:
    vm_object
  end

  def parse_quantity(value)
    return nil if value.nil?

    begin
      value.iec_60027_2_to_i
    rescue
      value.decimal_si_to_f
    end
  end

  def process_status(vm_object, interfaces, node_name)
    hw_object = hw_collection.find_or_build(vm_object)

    # Create the inventory object for vm network device
    hardware_networks(hw_object, interfaces, node_name)
  end

  def hardware_networks(hw_object, interfaces, node_name)
    return nil if interfaces.nil? || interfaces.empty?

    interfaces.each do |iface|
      ip_address, prefix_length = iface[:ipAddress]&.split('/')
      next unless ip_address

      subnet_mask = IPAddr.new("255.255.255.255").mask(prefix_length).to_s if prefix_length

      network_collection.find_or_build_by(
        :hardware  => hw_object,
        :ipaddress => ip_address,
      ).assign_attributes(
        :ipaddress   => ip_address,
        :hostname    => node_name,
        :subnet_mask => subnet_mask
      )
    end
  end

  def process_templates(objects)
    objects.each do |object|
      process_template(object)
    end
  end

  def process_template(object)
    # Get the basic information:
    uid = object.metadata.uid
    vm  = vm_from_objects(object.objects)
    return if vm.nil?

    # Add the inventory object for the template:
    template_object = template_collection.find_or_build(uid)
    template_object.connection_state = 'connected'
    template_object.ems_ref = uid
    template_object.name = object.metadata.name
    template_object.raw_power_state = 'never'
    template_object.template = true
    template_object.uid_ems = uid
    template_object.location = object.metadata.namespace

    # Add the inventory object for the hardware:
    process_hardware(template_object, object.parameters, object.metadata.labels, vm.dig(:spec, :template, :spec, :domain), vm.dig(:spec, :template, :spec, :volumes), vm.dig(:spec, :dataVolumeTemplates))

    # Add the inventory object for the OperatingSystem
    process_os(template_object, object.metadata.labels, object.metadata.annotations)
  end

  def vm_from_objects(objects)
    vm = nil
    objects.each do |object|
      if object[:kind] == "VirtualMachine"
        vm = object
      end
    end
    vm
  end

  def process_hardware(template_object, params, labels, domain, volumes = nil, data_volume_templates = nil)
    hw_object = hw_collection.find_or_build(template_object)
    memory = default_value(params, 'MEMORY') || domain.dig(:memory, :guest)
    hw_object.memory_mb = parse_quantity(memory) / 1.megabytes.to_f if memory
    cpu = default_value(params, 'CPU_CORES') || domain.dig(:cpu, :cores)
    hw_object.cpu_cores_per_socket = cpu
    hw_object.cpu_total_cores = cpu
    hw_object.guest_os = labels&.dig(OS_LABEL_SYMBOL)

    # Add the inventory objects for the disk:
    process_disks(hw_object, domain, nil, volumes, nil, data_volume_templates)
  end

  def default_value(params, name)
    name_param = params.detect { |param| param[:name] == name }
    name_param[:value] if name_param
  end

  def process_disks(hw_object, domain, namespace, volumes = nil, volume_status = nil, data_volume_templates = nil)
    return if domain.dig(:devices, :disks).nil?

    # Build lookup indexes from the volumes, volumeStatus, and dataVolumeTemplates lists, keyed by name
    volumes_by_name               = (volumes || []).index_by { |v| v[:name] }
    volume_status_by_name         = (volume_status || []).index_by { |v| v[:name] }
    data_volume_templates_by_name = (data_volume_templates || []).index_by { |d| d.dig(:metadata, :name) }

    domain.dig(:devices, :disks).each do |disk|
      disk_name   = disk[:name]
      volume      = volumes_by_name[disk_name]
      vol_status  = volume_status_by_name[disk_name]

      # Resolve the PVC claim name from the matching volume entry
      data_volume_name = volume&.dig(:dataVolume, :name)
      pvc_claim = volume&.dig(:persistentVolumeClaim, :claimName) ||
                  data_volume_name ||
                  vol_status&.dig(:persistentVolumeClaimInfo, :claimName)

      # Look up PVC for use as fallback when vol_status is absent (stopped VM)
      pvc = namespace && pvc_claim ? collector.pvc(pvc_claim, namespace) : nil

      # Look up dataVolumeTemplate for size when no PVC exists (e.g. templates with ${NAME} placeholders)
      dvt = data_volume_templates_by_name[data_volume_name]

      # Resolve disk size, type, and thinness — prefer volumeStatus (running VM), fall back to PVC, then dataVolumeTemplate
      size = parse_quantity(vol_status&.dig(:persistentVolumeClaimInfo, :capacity, :storage)) ||
             parse_quantity(pvc&.dig(:spec, :resources, :requests, :storage)) ||
             parse_quantity(dvt&.dig(:spec, :storage, :resources, :requests, :storage))
      size_on_disk = vol_status&.dig(:size) ||
                     parse_quantity(pvc&.dig(:status, :capacity, :storage))
      # Thickness is determined by preallocation annotations on the PVC, or the preallocated flag
      # from volumeStatus (set by CDI when cdi.kubevirt.io/storage.preallocation is true).
      # Absence of any preallocation indicator means the disk is thin (sparse).
      thick = vol_status&.dig(:persistentVolumeClaimInfo, :preallocated) == true || pvc_preallocation_annotations?(pvc)

      disk_object = disk_collection.find_or_build_by(
        :hardware    => hw_object,
        :device_name => disk_name
      )
      # Treat unsubstituted template placeholders (e.g. "${NAME}") as absent
      resolved_claim = pvc_claim&.match?(/\$\{.+\}/) ? nil : pvc_claim

      disk_object.device_name     = disk_name
      disk_object.filename        = resolved_claim
      disk_object.location        = resolved_claim || vol_status&.dig(:target)
      disk_object.device_type     = detect_device_type(disk)
      disk_object.present         = true
      disk_object.mode            = 'persistent'
      disk_object.controller_type = disk.dig(disk_object.device_type.to_sym, :bus)
      disk_object.bootable        = disk[:bootOrder] == 1
      disk_object.size            = size
      disk_object.size_on_disk    = size_on_disk
      disk_object.disk_type       = thick ? "thick" : "thin"
      disk_object.thin            = !thick
      disk_object.ems_ref         = disk_name
    end
  end

  def detect_device_type(disk)
    if disk[:cdrom].present?
      'cdrom'
    elsif disk[:floppy].present?
      'floppy'
    else
      'disk'
    end
  end

  PREALLOCATION_ANNOTATIONS = %w[
    cdi.kubevirt.io/storage.preallocation
    storage.preallocation
    storage.thick-provisioned
  ].freeze

  def pvc_preallocation_annotations?(pvc)
    return false if pvc.nil?

    annotations = pvc&.dig(:metadata, :annotations) || {}
    annotations.any? do |key, value|
      PREALLOCATION_ANNOTATIONS.any? { |suffix| key.to_s.end_with?(suffix) } && value.to_s == 'true'
    end
  end

  def process_os(template_object, labels, annotations)
    os_object = vm_os_collection.find_or_build(template_object)
    os_object.product_name = labels&.dig(OS_LABEL_SYMBOL)
    tags = annotations&.dig(:tags) || []
    os_object.product_type = if tags.include?("linux")
                               "linux"
                             elsif tags.include?("windows")
                               "windows"
                             else
                               "other"
                             end
  end
end
