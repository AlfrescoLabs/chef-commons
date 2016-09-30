# Module handling the logic to start multiple alfresco node in AWS instances one by one to avoid race conditions with DB
# A bucket creation is used as flag to indicate a node is starting and configuring
# Logic:
# AWS Node1 initiates in AWS and create the bucket (start method)
# AWS Node1 starts alfresco redeploy (alfresco is starting)
# AWS Node1 wait till alfresco service is up and running (wait_while_service_up method)
# AWS Node1 deletes the bucket (stop method)
# If any other node starts up while Node1 is starting, Node2 will wait till bucket is deleted and then will recreate the bucket
# NOTE: This module needs aws-sdk preinstalled to work (recipe: commons::install_aws_sdk)

module InstanceSemaphore

    include Chef::Mixin::ShellOut

    #loading gems in functions to avoid chef compilation errors
    def load_net_http
      require 'net/http'
    end

    def load_uri
       require 'uri'
    end

    def load_aws_sdk
      require 'aws-sdk'
    end

    # Try to create a bucket in the specified aws-region
    # If the bucket already exists, the create_bucket will throw an exception and the
    # method will attempt a `max_retry_count` times to create it (wating for other Alfresco nodes to delete the bucket)
    # Be aware that using `us-east-1` region may not cause the `create_bucket` to throw any exception
    def start(node)
      load_aws_sdk
      retry_count = 0
      hostname = node['hostname']
      s3_bucket_name = node['semaphore']['s3_bucket_name']
      sleep_seconds = node['semaphore']['sleep_create_bucket_seconds']

      s3 = Aws::S3::Client.new(region: node['semaphore']['aws_region'])

      while true
        begin
          puts "[#{hostname}] Creating bucket #{s3_bucket_name}"
          bucket = s3.create_bucket(bucket: s3_bucket_name)
          return true
          break
        rescue Aws::S3::Errors::ServiceError => e
          puts e.message
          if retry_count > node['semaphore']['max_retry_count']
             raise 'Max number retry reached'
          else
            retry_count += 1
            puts "[#{hostname}] sleeping #{sleep_seconds} seconds until bucket has been deleted"
            sleep(sleep_seconds)
            next
          end
        end
      end
    end

    # Check if the provided url `service_url` (e.g. http://localhost:8070/alfresco) is available
    # It will try a `max_retry_count` times
    def wait_while_service_up(node)
        load_net_http
        load_uri
        retry_count = 0
        sleep_seconds = node['semaphore']['sleep_wait_service_seconds']
        url = node['semaphore']['service_url']
        accepted_responses = node['semaphore']['service_accepted_responses']
        uri = URI(url)
        puts "Checking if [#{url}] is up"
        while retry_count < node['semaphore']['max_retry_count']
          begin
            puts "Attempt ##{retry_count}"
            res = Net::HTTP.get_response(uri).code
            if accepted_responses.include? res
              puts "#{url} is up!"
              return true
              break
            else
              puts "[#{res}] #{url} not available yet - sleep #{sleep_seconds} seconds"
              sleep(sleep_seconds)
              retry_count += 1
              next
            end
          rescue Timeout::Error
            puts "Timeout - Sleeping #{sleep_seconds} seconds and retrying"
            sleep(sleep_seconds)
            retry_count += 1
            next
          rescue Errno::EINVAL, Errno::ECONNRESET, EOFError,
                 Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
            puts "Error while getting http response -> exit"
            puts e.message
            return false
            break
          end
        end
        puts 'Max number retry reached'
        return false
    end

    # Try to delete a bucket in the specified aws-region
    # method will attempt a `max_retry_count` times to delete it in case of AWS service error
    def stop(node)
      load_aws_sdk
      sleep_seconds = node['semaphore']['sleep_delete_bucket_seconds']
      retry_count = 0
      hostname = node['hostname']
      s3 = Aws::S3::Client.new(region: node['semaphore']['aws_region'])
      puts "[#{hostname}] Deleting bucket #{node['semaphore']['s3_bucket_name']}"
      while true
        begin
          s3.delete_bucket(bucket: node['semaphore']['s3_bucket_name'])
          return true
          break
        rescue Aws::S3::Errors::NoSuchBucket
          puts "No such bucket to delete -> exit"
          return true
          break
        rescue Aws::S3::Errors::ServiceError => e
          if retry_count > node['semaphore']['max_retry_count']
             puts e.message
             puts 'Max number retry reached'
             raise 'Max number retry reached'
          else
            retry_count += 1
            puts e.message
            puts "[#{hostname}] Cannot delete the bucket sleeping #{sleep_seconds} seconds to try to delete it again"
            sleep(sleep_seconds)
            next
          end
        end
      end
    end
end
