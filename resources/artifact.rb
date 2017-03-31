resource_name :artifact

property :resource_title, String, name_property: true
property :term_delimiter_start, String, default: '@@'
property :term_delimiter_end, String, default: '@@'
property :property_equals_sign, String, default: '='
property :global_timeout, String, default: 600
property :repos_databag, String, default: 'maven_repos'
property :attribute_repos, default: lazy { node['commons']['maven']['repositories'] }
property :chef_cache, String, default: lazy { node['commons']['cache_folder'] || Chef::Config[:file_cache_path] }
property :pathPrefix, default: lazy { node['artifactPathPrefix'] }
property :destinationPrefix, default: lazy { node['destinationPrefix'] }
property :artifacts, default: lazy { node['artifacts'] } || nil
property :artifacts_type, String, default: 'jar'
property :artifacts_owner, String, default: 'root'

default_action :create

action :create do
  maven_repos_str = []

  if attribute_repos
    attribute_repos.each do |repo_id, repo|
      maven_repos_str.push "#{repo_id}::::#{repo['url']}"
    end
  end

  begin
    repos = data_bag(repos_databag)
    if repos
      repos.each do |repo|
        repo = data_bag_item('maven_repos', repo)
        maven_repos_str.push "#{repo['id']}::::#{repo['url']}"
      end
    end
  rescue
    Chef::Log.warn('Cannot find databag ' + repos_databag + '; skipping repo option in Maven commands')
  end

  directory 'chef-cache' do
    path chef_cache
    owner 'root'
    group 'root'
    mode 00755
    action :create
  end

  unless artifacts.nil?
    artifacts.each do |artifact_name, artifact|
      url             = artifact[:url]
      path            = artifact[:path] ? "#{pathPrefix}/#{artifact[:path]}" : nil
      artifact_id     = artifact[:artifactId]
      group_id        = artifact[:groupId]
      version         = artifact[:version]
      artifact_type   = artifact[:type] ? artifact[:type] : artifacts_type
      s3_bucket       = artifact[:s3_bucket]
      s3_filename     = artifact[:s3_filename]
      owner           = artifact[:owner] ? artifact[:owner] : artifacts_owner
      unzip           = artifact[:unzip] ? artifact[:unzip] : false
      classifier      = artifact[:classifier] ? artifact[:classifier] : ''
      subfolder       = artifact[:subfolder] ? artifact[:subfolder] : ''
      destination     = artifact[:destination] ? artifact[:destination] : destinationPrefix
      destination_name = artifact[:destinationName] ? artifact[:destinationName] : artifact_name
      enabled         = artifact[:enabled] ? artifact[:enabled] : false
      properties      = artifact[:properties] ? artifact[:properties] : []
      terms           = artifact[:terms] ? artifact[:terms] : []
      filtering_mode  = artifact[:filtering_mode] ? artifact[:filtering_mode] : 'replace'
      filename_with_ext = "#{destination_name}.#{artifact_type}"
      destination_path = "#{destination}/#{destination_name}"

      next unless enabled
      log "Processing artifact #{destination_name}.#{artifact_type}; unzip: #{unzip}"
      if path
        # TODO: - test it
        # filename_with_ext = File.basename(path)
        execute "cache-artifact-#{destination_name}" do
          command "cp -Rf #{path} #{chef_cache}/#{filename_with_ext}"
        end
      elsif url
        # TODO: - test it
        # filename_with_ext = File.basename(url)
        remote_file "#{chef_cache}/#{filename_with_ext}" do
          source url
        end
      elsif artifact_id && group_id && version
        maven artifact_name do
          artifact_id artifact_id
          group_id group_id
          version version
          classifier classifier if classifier != ''
          # if timeout != ''
          #   timeout     timeout
          # end
          action :put
          dest chef_cache
          owner owner
          packaging artifact_type
          repositories maven_repos_str
        end
      elsif s3_bucket && s3_filename
        execute "s3-cp-#{s3_filename}" do
          command "aws s3 cp s3://#{s3_bucket}/#{s3_filename} #{chef_cache}/#{filename_with_ext}"
        end
      elsif s3_bucket
        execute "sync-s3://#{s3_bucket}" do
          command "aws s3 sync s3://#{s3_bucket} #{chef_cache}/#{destination_name}"
          returns [0, 2]
        end
        execute "copying-folder-#{destination_name}" do
          command "cp -Rf #{chef_cache}/#{destination_name} #{destination}/#{destination_name}; chown -R #{owner} #{destination}/#{destination_name}"
          user owner
          only_if "test -d #{chef_cache}/#{destination_name}"
        end
      end

      directory "fix-permissions-#{destination}" do
        path destination
        owner owner
        action :create
        recursive true
      end

      if unzip == true
        execute "unzipping-package-#{destination_name}" do
          command "unzip -q -u -o  #{chef_cache}/#{filename_with_ext} #{subfolder} -d #{destination_path}; chown -R #{owner} #{destination_path}; chmod -R 755 #{destination_path}"
          user owner
          only_if "test -f #{chef_cache}/#{filename_with_ext}"
        end
      else
        execute "copying-package-#{filename_with_ext}" do
          command "cp -Rf #{chef_cache}/#{filename_with_ext} #{destination}/#{filename_with_ext}; chown -R #{owner} #{destination}/#{filename_with_ext}"
          user owner
          only_if "test -f #{chef_cache}/#{filename_with_ext}"
        end
      end
      properties.each do |file_to_patch, property_map|
        filtering_mode = property_map[:filtering_mode] ? property_map[:filtering_mode] : filtering_mode
        if filtering_mode == 'replace'
          property_map.each do |prop_name, prop_value|
            file_replace_line "replace-#{prop_name}-on-#{file_to_patch}" do
              path "#{destination_path}/#{file_to_patch}"
              replace "#{prop_name}#{property_equals_sign}"
              with "#{prop_name}#{property_equals_sign}#{prop_value}"
              only_if "test -f #{destination_path}/#{file_to_patch}"
            end
          end
        elsif filtering_mode == 'append'
          property_map.each do |prop_name, prop_value|
            file_append "append-#{prop_name}-to-#{file_to_patch}" do
              path "#{destination_path}/#{file_to_patch}"
              line "#{prop_name}#{property_equals_sign}#{prop_value}"
              only_if "test -f #{destination_path}/#{file_to_patch}"
              only_if { prop_name != 'filtering_mode' }
            end
          end
        end
      end

      terms.each do |file_to_patch, term_map|
        term_map.each do |term_match, term_replacement|
          file_replace "replace-#{term_match}-in-#{file_to_patch}" do
            path "#{destination}/#{artifact_name}/#{file_to_patch}"
            replace "#{term_delimiter_start}#{term_match}#{term_delimiter_end}"
            with term_replacement
            only_if "test -f #{destination}/#{artifact_name}/#{file_to_patch}"
          end
        end
      end
    end
  end
end
