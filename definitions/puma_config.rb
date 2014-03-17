define :puma_config, :owner => 'root', :group => 'root', :directory  => nil, :puma_directory => nil, :working_dir => nil, :rackup => nil,
                     :environment => "production", :daemonize => true, :pidfile => nil, :config_path => nil, :state_path => nil,
                     :stdout_redirect => nil, :stderr_redirect => nil, :output_append => true,
                     :quiet => false, :thread_min => 0, :thread_max => 16, :bind => nil, :control_app_bind => nil,
                     :workers => 0, :activate_control_app => true, :logrotate => true, :exec_prefix => nil,
                     :config_source => nil, :config_cookbook => nil,
                     :preload_app => false, :on_worker_boot => nil do

  # Set defaults if not supplied by caller.
  # Working directory of rails app (where config.ru is)
  unless params[:directory]
    params[:directory] = "/srv/www/#{params[:name]}"
  end

  unless params[:working_dir]
    params[:working_dir] = "#{params[:directory]}/current"
  end

  unless params[:puma_directory]
    params[:puma_directory] = "#{params[:directory]}/shared/puma"
  end

  unless params[:config_path]
    params[:config_path] = "#{params[:puma_directory]}/#{params[:name]}.config"
  end

  unless params[:state_path]
    params[:state_path] = "#{params[:puma_directory]}/#{params[:name]}.state"
  end

  unless params[:bind]
    params[:bind] = "unix://#{params[:puma_directory]}/#{params[:name]}.sock"
  end

  unless params[:control_app_bind]
    params[:control_app_bind] = "unix://#{params[:puma_directory]}/#{params[:name]}_control.sock"
  end

  unless params[:pidfile]
    params[:pidfile] = "#{params[:directory]}/shared/pids/#{params[:name]}.pid"
  end

  unless params[:stdout_redirect]
    params[:stdout_redirect] = "#{params[:working_dir]}/log/puma.log"
  end

  unless params[:stderr_redirect]
    params[:stderr_redirect] = "#{params[:working_dir]}/log/puma.error.log"
  end

  unless params[:exec_prefix]
    params[:exec_prefix] = "bundle exec"
  end

  unless params[:config_source]
    params[:config_source] = "puma.rb.erb"
  end

  unless params[:config_cookbook]
    params[:config_cookbook] = "opsworks-puma"
  end

  # Create app working directory with owner/group if specified
  directory params[:puma_directory] do
    recursive true
    owner params[:owner] if params[:owner]
    group params[:group] if params[:group]
  end

  template params[:name] do
    source params[:config_source]
    path params[:config_path]
    cookbook params[:config_cookbook]
    mode "0644"
    owner params[:owner] if params[:owner]
    group params[:group] if params[:group]
    variables params
  end

  template "puma_start.sh" do
    source "puma_start.sh.erb"
    path "#{params[:puma_directory]}/puma_start.sh"
    cookbook "opsworks-puma"
    mode "0755"
    owner params[:owner] if params[:owner]
    group params[:group] if params[:group]
    variables params
  end

  template "#{params[:name]}-puma" do
    source "init.d.sh.erb"
    path "/etc/init.d/#{params[:name]}-puma"
    cookbook "opsworks-puma"
    mode "0755"
    owner params[:owner] if params[:owner]
    group params[:group] if params[:group]
    variables params
  end

  if params[:logrotate]
    logrotate_app puma_params[:name] do
      cookbook "logrotate"
      path [ puma_params[:stdout_redirect], puma_params[:stderr_redirect] ]
      frequency "daily"
      rotate 30
      size "5M"
      options ["missingok", "compress", "delaycompress", "notifempty", "dateext"]
      variables puma_params
    end
  end
end
