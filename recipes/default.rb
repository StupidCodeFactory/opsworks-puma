ruby_block "ensure only our unicorn version is installed by deinstalling any other version" do
  block do
    ensure_only_gem_version('puma', node[:puma][:version])
  end
end

include_recipe "nginx"


node[:deploy].each do |application, deploy|
  puma_config application do
    directory
    environment deploy[:rails_env]
    logrotate node[:puma][:logrotate]
    thread_min node[:puma][:thread_min]
    thread_max node[:puma][:thread_min]
    workers node[:puma][:workers]
  end
end

