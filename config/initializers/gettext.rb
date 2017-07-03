Vmdb::Gettext::Domains.add_domain(
  'ManageIQ_Providers_KubeVirt',
  ManageIQ::Providers::KubeVirt::Engine.root.join('locale').to_s,
  :po
)
