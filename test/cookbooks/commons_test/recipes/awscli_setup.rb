awscli 'install awscli' do
  only_if {node['commons']['install_awscli']}
end
