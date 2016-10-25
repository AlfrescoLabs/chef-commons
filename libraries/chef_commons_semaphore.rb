# Module handling the logic to start multiple Alfresco node in AWS instances one by one to avoid race conditions with DB
# A bucket creation is used as flag to indicate a node is starting and configuring
#
# It handles both a PARALLEL and SERIAL Logic
#
# PARALLEL Logic (one node starts, when it's finished all the others start):
#
# AWS Node1 initiates in AWS and create the bucket (start_parallel method)
# AWS Node1 starts alfresco redeploy (alfresco is starting)
# AWS Node1 wait till alfresco service is up and running (wait_while_service_up_parallel method)
# AWS Node1 create a key into a defined bucket to mark it as bootrapped
# AWS Node1 deletes the bucket (stop method)
# If any other node starts up while Node1 is starting, Node2 will wait till bucket is deleted and then will recreate the bucket
#
# SERIAL Logic (each node wait for the previous to start):
#
# AWS Node1 initiates in AWS and create the bucket (start method)
# AWS Node1 starts alfresco redeploy (alfresco is starting)
# AWS Node1 wait till alfresco service is up and running (wait_while_service_up method)
# AWS Node1 deletes the bucket (stop method)
# If any other node starts up while Node1 is starting, Node2 will wait till bucket is deleted and then will recreate the bucket
# All the nodes will start in serial one after the other
#
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
      s3_bucket_name = node['semaphore']['s3_bucket_name']
      sleep_seconds = node['semaphore']['sleep_create_bucket_seconds']

      s3 = Aws::S3::Client.new(region: node['semaphore']['aws_region'])

      while true
        retry_count += 1
        begin
          puts "[Semaphore][start] Creating bucket #{s3_bucket_name}"
          bucket = s3.create_bucket(bucket: s3_bucket_name)
          puts "[Semaphore][start] Bucket #{s3_bucket_name} created!"
          return true
        rescue Aws::S3::Errors::InvalidBucketName => e
	        puts "[Semaphore][start] Invalid bucket name '#{s3_bucket_name}' -> #{e.message}"
          return false
        rescue Aws::S3::Errors::ServiceError => e
          puts "[Semaphore][start] Error while creating the bucket TYPE: #{e.class} MESSAGE: #{e.message}"
          if retry_count > node['semaphore']['max_retry_count']
             puts '[Semaphore][start] Max number retry reached'
             return false
          else
            puts "[Semaphore][start] ##{retry_count} sleeping #{sleep_seconds} seconds until bucket has been deleted"
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
        puts "[Semaphore][wait_while_service_up] Checking if [#{url}] is up"
        while retry_count < node['semaphore']['max_retry_count']
          begin
            puts "[Semaphore][wait_while_service_up] Attempt ##{retry_count}"
            res = Net::HTTP.get_response(uri).code
            if accepted_responses.include? res
              puts "#{url} is up!"
              return true
            else
              puts "[Semaphore][wait_while_service_up] [#{res}] #{url} not available yet - sleep #{sleep_seconds} seconds"
              sleep(sleep_seconds)
              retry_count += 1
              next
            end
          rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
            puts "[Semaphore][wait_while_service_up] Error #{e.class}: #{e.message} while getting http response"
            puts "[Semaphore][wait_while_service_up] ##{retry_count} Sleeping #{sleep_seconds} seconds and retrying"
            sleep(sleep_seconds)
            retry_count += 1
            next
          rescue StandardError => e
            puts "[Semaphore][wait_while_service_up] Error while getting http response - TYPE: #{e.class} MESSAGE: #{e.message} -> exit"
            return false
          end
        end
        puts '[Semaphore][wait_while_service_up] Max number retry reached'
        return false
    end

    # Try to delete a bucket in the specified aws-region
    # method will attempt a `max_retry_count` times to delete it in case of AWS service error
    def stop(node)
      load_aws_sdk
      sleep_seconds = node['semaphore']['sleep_delete_bucket_seconds']
      retry_count = 0
      s3 = Aws::S3::Client.new(region: node['semaphore']['aws_region'])
      puts "[Semaphore][stop] Deleting bucket #{node['semaphore']['s3_bucket_name']}"
      while true
        begin
          s3.delete_bucket(bucket: node['semaphore']['s3_bucket_name'])
          puts "[Semaphore][stop] Bucket #{node['semaphore']['s3_bucket_name']} deleted!"
          return true
        rescue Aws::S3::Errors::NoSuchBucket
          puts "[Semaphore][stop] No such bucket to delete -> exit"
          return true
        rescue Aws::S3::Errors::ServiceError => e
          if retry_count > node['semaphore']['max_retry_count']
             puts "[Semaphore][stop] Error while deleting the bucket TYPE: #{e.class} MESSAGE: #{e.message}"
             puts '[Semaphore][stop] Max number retry reached'
             return false
          else
            retry_count += 1
            puts e.message
            puts "[Semaphore][stop] Cannot delete the bucket sleeping #{sleep_seconds} seconds to try to delete it again"
            sleep(sleep_seconds)
            next
          end
        end
      end
    end

    # method to create a bucket into the specified region, with specified backet name
    # it will attempt a `retries` number of time and wait `timeout` seconds
    # if the bucket already exists it will return false and will not retry
    def create_bucket(region,s3_bucket_name,retries,timeout)
      load_aws_sdk
      retry_count = 0
      s3_client = Aws::S3::Client.new(region: region)
      while retry_count < retries
        retry_count += 1
        begin
          puts "[Semaphore][create_bucket] Creating bucket #{s3_bucket_name}"
          bucket = s3_client.create_bucket(bucket: s3_bucket_name)
          puts "[Semaphore][create_bucket] Bucket #{s3_bucket_name} created!"
          return true
        rescue Aws::S3::Errors::BucketAlreadyExists, Aws::S3::Errors::BucketAlreadyOwnedByYou => e
          puts "[Semaphore][create_bucket] Bucket #{s3_bucket_name} already exists"
          puts "[Semaphore][create_bucket] #{e}"
          return false
        rescue  Aws::S3::Errors::InvalidBucketName => e
          puts e
          raise e.message
        rescue Aws::S3::Errors::ServiceError => e
          puts "[Semaphore][create_bucket] Error #{e.class}: #{e.message} while creating bucket #{s3_bucket_name}"
          puts "[Semaphore][create_bucket] [##{retry_count}] Sleeping #{timeout} seconds and retrying"
          sleep(timeout)
          next
        end
      end
      puts '[Semaphore][create_bucket] Max number retry reached'
      return false
    end

    # checks whether an instance has already bootstrapped checking the existance of a object into a bucket
    # in case of AWS errors it will retry a max_retry_count times
    def bootstrapped?(node)
      load_aws_sdk
      sleep_seconds = node['semaphore']['sleep_bootstrap']
      s3_client = Aws::S3::Client.new(region: node['semaphore']['aws_region'])
      retry_count = 0
      while retry_count < node['semaphore']['max_retry_count']
        begin
          s3_client.get_object(bucket: node['semaphore']['s3_bucket_name_done'], key: node['semaphore']['bootstrapped_key'])
          puts "[Semaphore][bootstrapped?] An instance alredy bootstrapped!"
          return true
        rescue Aws::S3::Errors::NoSuchKey => e
          puts "[Semaphore][bootstrapped?] \
          #{node['semaphore']['bootstrapped_key']} does not exist in #{node['semaphore']['s3_bucket_name_done']} -> No instance bootstrapped"
          return false
        rescue Aws::S3::Errors::ServiceError => e
          puts "[Semaphore][bootstrapped?] Error #{e.class}: \
          #{e.message} while getting object #{node['semaphore']['bootstrapped_key']} from bucket #{node['semaphore']['s3_bucket_name_done']}"
          puts "[Semaphore][bootstrapped?] ##{retry_count} Sleeping #{sleep_seconds} seconds and retrying"
          sleep(sleep_seconds)
          retry_count += 1
          next
        end
      end
      puts '[Semaphore][bootstrapped?] Max number retry reached'
      return false
    end

    # method that waits while another instance has bootrapped using the `bootstrapped?`
    def wait_while_bootrapped(node)
      load_aws_sdk
      sleep_seconds = node['semaphore']['sleep_wait_bootrap_seconds']
      retry_count = 0

      while retry_count < node['semaphore']['max_retry_count']
        puts "[Semaphore][wait_while_bootrapped] Attempt[#{retry_count}] to check node bootstrapped"
        if bootstrapped?(node)
          puts "[Semaphore][wait_while_bootrapped] Instance Bootstrapped!"
          return true
        else
          sleep(sleep_seconds)
          retry_count += 1
          next
        end
      end
      puts "[Semaphore][wait_while_bootrapped] Max number of attempts reached to wait bootrapping"
      return false
    end

    # Method to start a parallel semaphore
    # if a node already bootstrapped it exists
    # if no node bootrapped it checks whether it can create the lock (bucket)
    # if it can create the loc it will continute
    # otherwise it will wait till an instance has bootrapped and then exit
    def start_parallel(node)
      load_aws_sdk
      puts '[Semaphore][start_parallel] Start Parallel'
      region = node['semaphore']['aws_region']

      if node['semaphore']['s3_bucket_done']['force_creation']
        puts "Forcing creation of bucket #{node['semaphore']['s3_bucket_name_done']}"
        create_bucket(region,node['semaphore']['s3_bucket_name_done'],
        node['semaphore']['max_retry_count'],node['semaphore']['create_bucket']['timeout'])
      end

      if bootstrapped?(node)
        return true
      else
        s3_bucket_name = node['semaphore']['s3_bucket_name']
        is_bucket_created = create_bucket(region,s3_bucket_name,node['semaphore']['max_retry_count'],
        node['semaphore']['create_bucket']['timeout'])
        if is_bucket_created
          puts '[Semaphore][start_parallel] bucket created -> exit'
          return true
        else
          puts '[Semaphore][start_parallel] bucket not created -> waiting bootstrap'
          wait_while_bootrapped(node)
        end
      end
    end

    # wait till service is up.
    # if it has not bootrapped yet or it's forced it will wait till service is up
    # otherwise it will exit
    def wait_while_service_up_parallel(node)
      load_aws_sdk
      puts '[Semaphore][wait_while_service_up_parallel] Wait While Service Up Parallel'
      force_wait = node['semaphore']['wait_while_service_up']['force_wait']
      is_bootstrapped = false
      puts "[Semaphore][wait_while_service_up_parallel] force wait: #{force_wait}"
      if force_wait ||  is_bootstrapped = !bootstrapped?(node)
        puts "[Semaphore][wait_while_service_up_parallel] is_bootstrapped: #{is_bootstrapped}" if !force_wait
        return wait_while_service_up(node)
      else
        puts "[Semaphore][wait_while_service_up_parallel] exit"
        return true
      end
    end

    # If no instance has bootrapped yet it will create an object into the bucket with name `
    # defined in node['semaphore']['bootstrapped_key']` otherwise il will create an object with
    # the ec2 instance_id name
    def stop_parallel(node)
      load_aws_sdk
      puts '[Semaphore][stop_parallel] Stop Parallel'
      if !bootstrapped?(node)
        puts '[Semaphore][stop_parallel] No instance bootstrapped yet!'
        write_object(node['semaphore']['aws_region'],
         node['semaphore']['s3_bucket_name_done'],
         node['semaphore']['bootstrapped_key'],
         "Bootrapped instance_id: #{node['ec2']['instance_id']}",
         node['semaphore']['write_object']['timeout'],
         node['semaphore']['max_retry_count'])
      else
        puts '[Semaphore][stop_parallel] An instance already bootstrapped!'
        write_object(node['semaphore']['aws_region'],
          node['semaphore']['s3_bucket_name_done'],
          node['ec2']['instance_id'],
          "Bootrapped instance_id: #{node['ec2']['instance_id']}",
          node['semaphore']['write_object']['timeout'],
          node['semaphore']['max_retry_count'])
      end
      stop(node)
    end

    # It wrice an object in the specified region, inside the bucket with specified body
    # it will attempt a retries number of times and sleep for timeout seconds in case of errors
    def write_object(region,s3_bucket_name,object_name,body,timeout,retries)
      load_aws_sdk
      puts '[Semaphore][write_object] Writing Object'
      retry_count = 0
      s3_client = Aws::S3::Client.new(region: region)
      while retry_count < retries
        begin
          puts "[Semaphore][write_object] Writing Object #{object_name} in bucket #{s3_bucket_name}"
          s3_client.put_object(bucket: s3_bucket_name, key: object_name, body: body)
          puts "[Semaphore][write_object] Object in bucket!"
          return true
        rescue Aws::S3::Errors::ServiceError => e
          puts "[Semaphore][write_object] Error #{e.class}: #{e.message} while creating object #{object_name} in #{s3_bucket_name}"
          puts "[Semaphore][write_object] [##{retry_count}] Sleeping #{timeout} seconds and retrying"
          sleep(timeout)
          retry_count += 1
          next
        end
      end
      puts "[Semaphore][write_object] Max number of attempts reached to write the object"
      return false
    end

end
