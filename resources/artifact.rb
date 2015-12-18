resource_name :artifact

property :resource_title, String, name_property: true
property :term_delimiter_start, String, defaut: '@@'
property :term_delimiter_end, String, default: '@@'
property :property_equals_sign, String, default: '='
property :global_timeout, String, default: 600
property :repos_databag, String, default: 'maven_repos'
property :attribute_repos, default: lazy { node['artifact-deployer']['maven']['repositories'] }
property :chef_cache, String, default: lazy { node['artifact-deployer']['cache_folder'] || Chef::Config[:file_cache_path] }
property :pathPrefix, default: lazy { node['artifactPathPrefix'] }
property :artifacts, default: lazy { node['artifacts'] } || nil

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
    artifacts.each do |artifactName, artifact|
      url             = artifact[:url]
      path            = artifact[:path] ? "#{pathPrefix}/#{artifact[:path]}" : nil
      artifact_id     = artifact[:artifactId]
      group_id        = artifact[:groupId]
      version         = artifact[:version]
      artifactType    = artifact[:type] ? artifact[:type] : 'jar'
      s3_bucket       = artifact[:s3_bucket]
      s3_filename     = artifact[:s3_filename]
      owner           = artifact[:owner] ? artifact[:owner] : 'root'
      unzip           = artifact[:unzip] ? artifact[:unzip] : false
      classifier      = artifact[:classifier] ? artifact[:classifier] : ''
      subfolder       = artifact[:subfolder] ? artifact[:subfolder] : ''
      destination     = artifact[:destination]
      timeout         = artifact[:timeout] ? artifact[:timeout] : global_timeout
      destinationName = artifact[:destinationName] ? artifact[:destinationName] : artifactName
      enabled         = artifact[:enabled] ? artifact[:enabled] : false
      properties      = artifact[:properties] ? artifact[:properties] : []
      terms           = artifact[:terms] ? artifact[:terms] : []
      filtering_mode  = artifact[:filtering_mode] ? artifact[:filtering_mode] : 'replace'
      fileNameWithExt = "#{destinationName}.#{artifactType}"
      destinationPath = "#{destination}/#{destinationName}"

      if enabled == true
        log "Processing artifact #{destinationName}.#{artifactType}; unzip: #{unzip}"
        if path
          # TODO: - test it
          # fileNameWithExt = File.basename(path)
          execute "cache-artifact-#{destinationName}" do
            command "cp -Rf #{path} #{chef_cache}/#{fileNameWithExt}"
          end
        elsif url
          # TODO: - test it
          # fileNameWithExt = File.basename(url)
          remote_file "#{chef_cache}/#{fileNameWithExt}" do
            source url
          end
        elsif artifact_id && group_id && version
          maven artifactName do
            artifact_id artifact_id
            group_id group_id
            version version
            classifier classifier if classifier != ''
            timeout timeout if timeout != ''
            action :put
            dest chef_cache
            owner owner
            packaging artifactType
            repositories maven_repos_str
          end
        elsif s3_bucket && s3_filename
          execute "s3-cp-#{s3_filename}" do
            command "aws s3 cp s3://#{s3_bucket}/#{s3_filename} #{chef_cache}/#{fileNameWithExt}"
          end
        elsif s3_bucket
          execute "sync-s3://#{s3_bucket}" do
            command "aws s3 sync s3://#{s3_bucket} #{chef_cache}/#{destinationName}"
            returns [0, 2]
          end
          execute "copying-folder-#{destinationName}" do
            command "cp -Rf #{chef_cache}/#{destinationName} #{destination}/#{destinationName}; chown -R #{owner} #{destination}/#{destinationName}"
            user owner
            only_if "test -d #{chef_cache}/#{destinationName}"
          end
        end

        directory "fix-permissions-#{destination}" do
          path destination
          owner owner
          action :create
          recursive true
        end

        if unzip == true
          execute "unzipping-package-#{destinationName}" do
            command "unzip -q -u -o  #{chef_cache}/#{fileNameWithExt} #{subfolder} -d #{destinationPath}; chown -R #{owner} #{destinationPath}; chmod -R 755 #{destinationPath}"
            user owner
            only_if "test -f #{chef_cache}/#{fileNameWithExt}"
          end
        else
          execute "copying-package-#{fileNameWithExt}" do
            command "cp -Rf #{chef_cache}/#{fileNameWithExt} #{destination}/#{fileNameWithExt}; chown -R #{owner} #{destination}/#{fileNameWithExt}"
            user owner
            only_if "test -f #{chef_cache}/#{fileNameWithExt}"
          end
        end

        properties.each do |fileToPatch, propertyMap|
          filtering_mode  = propertyMap[:filtering_mode] ? propertyMap[:filtering_mode] : filtering_mode
          if filtering_mode == 'replace'
            propertyMap.each do |propName, propValue|
              file_replace_line "replace-#{propName}-on-#{fileToPatch}" do
                path "#{destinationPath}/#{fileToPatch}"
                replace "#{propName}="
                with "#{propName}=#{propValue}"
                only_if "test -f #{destinationPath}/#{fileToPatch}"
              end
            end
          elsif filtering_mode == 'append'
            propertyMap.each do |propName, propValue|
              file_append "append-#{propName}-to-#{fileToPatch}" do
                path "#{destinationPath}/#{fileToPatch}"
                line "#{propName}=#{propValue}"
                only_if "test -f #{destinationPath}/#{fileToPatch}"
              end
            end
          end
        end

        terms.each do |fileToPatch, termMap|
          termMap.each do |termMatch, termReplacement|
            file_replace "replace-#{termMatch}-in-#{fileToPatch}" do
              path "#{destination}/#{artifactName}/#{fileToPatch}"
              replace "#{term_delimiter_start}#{termMatch}#{term_delimiter_end}"
              with termReplacement
              only_if "test -f #{destination}/#{artifactName}/#{fileToPatch}"
            end
          end
        end
      end
    end
  end
end
