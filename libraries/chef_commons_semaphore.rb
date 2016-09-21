module InstanceSemaphore
  class << self

    include Chef::Mixin::ShellOut

    def load_aws_sdk
          require 'aws-sdk'
    end

    def start(node)
      load_aws_sdk
      retry_count = 0
      hostname = node['hostname']
      s3_bucket_name = node['semaphore']['s3_bucket_name']
      sleep_seconds = node['semaphore']['sleep_seconds']
      s3 = Aws::S3::Client.new(region: node['semaphore']['aws_region'])
      while true
        begin
          puts "[#{hostname}] Creating bucket #{s3_bucket_name}"
          bucket = s3.create_bucket(bucket: s3_bucket_name)
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

    def stop(node)
      load_aws_sdk
      retry_count = 0
      hostname = node['hostname']
      s3 = Aws::S3::Client.new(region: node['semaphore']['aws_region'])
      puts "[#{hostname}] Deleting bucket #{node['semaphore']['s3_bucket_name']}"
      while true
        begin
          s3.delete_bucket(bucket: node['semaphore']['s3_bucket_name'])
          break
        rescue Aws::S3::Errors::NoSuchBucket
          puts "No such bucket to delete -> exit"
          break
        rescue Aws::S3::Errors::ServiceError => e
          if retry_count > node['semaphore']['max_retry_count']
             raise 'Max number retry reached'
          else
            retry_count += 1
            puts e.message
            puts "[#{hostname}] Cannot delete the bucket sleeping 10 seconds to try to delete it again"
            sleep(10)
            next
          end
        end
      end
    end
  end
end

Chef::Recipe.send(:include, InstanceSemaphore)
