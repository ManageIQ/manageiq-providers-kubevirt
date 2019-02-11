$:.push(File.expand_path("../lib", __FILE__))

require "manageiq/providers/kubevirt/version"

Gem::Specification.new do |s|
  s.name        = "manageiq-providers-kubevirt"
  s.version     = ManageIQ::Providers::Kubevirt::VERSION
  s.authors     = ["KubeVirt Developers"]
  s.homepage    = "https://github.com/ManageIQ/manageiq-providers-kubevirt"
  s.summary     = "KubeVirt provider for ManageIQ"
  s.description = "KubeVirt provider for ManageIQ"
  s.licenses    = ["Apache-2.0"]

  s.files = Dir["{app,config,lib}/**/*"]

  s.add_runtime_dependency("fog-kubevirt", "~> 0.2.0")
  s.add_runtime_dependency("manageiq-providers-kubernetes", "~> 0.1.0")

  s.add_development_dependency("codeclimate-test-reporter", "~> 1.0.0")
  s.add_development_dependency("simplecov")
end
