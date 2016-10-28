default['semaphore']['max_retry_count'] = 15
default['semaphore']['aws_region'] = 'us-west-1'

default['semaphore']['sleep_create_bucket_seconds'] = 3
default['semaphore']['sleep_delete_bucket_seconds'] = 10
default['semaphore']['sleep_wait_service_seconds'] = 30
default['semaphore']['sleep_wait_bootrap_seconds'] = 60
default['semaphore']['sleep_bootstrap'] = 2
default['semaphore']['create_bucket']['timeout'] = 2
default['semaphore']['write_object']['timeout'] = 2

default['semaphore']['s3_bucket_name'] = "starting-instance"

default['semaphore']['s3_bucket_lock']['name'] = node['semaphore']['s3_bucket_name']
default['semaphore']['s3_bucket_lock']['aws_region'] = node['semaphore']['aws_region']

default['semaphore']['s3_bucket_done']['aws_region'] = 'us-west-1'
default['semaphore']['s3_bucket_done']['name'] = "starting-instance-done"
default['semaphore']['s3_bucket_done']['force_creation'] = false

default['semaphore']['service_url'] = 'http://localhost:8070/alfresco'
default['semaphore']['service_accepted_responses'] = %w(302 200)
default['semaphore']['parallel'] = false
default['semaphore']['bootstrapped_key'] = 'done'

default['semaphore']['wait_while_service_up']['force_wait'] = false
