# chef-commons
A collection of Chef libraries, custom resources, (recipe) wrappers and other useful tools used to manage Chef cookbook lifecycle.

## Chef libraries

### EC2 Discovery
### Semaphore
Details on the library implementation can be found on the library itself:
_libraries/chef_commons_semaphore.rb_
#### How to use it
Here an example on how to use the semaphore, with this list of recipes:

- commons::install_aws_sdk (to install the aws sdk used by the library)
- commons::start_instance (to start the semaphore)
- alfresco::redeploy (to configure and start alfresco on the instance)
- commons::wait_instance (it will wait Alfresco to start up)
- commons::stop_instance (it will notify the bootstrap of the instance has finished)

**Configurable attributes:**

```
default['semaphore']['max_retry_count']=15
default['semaphore']['aws_region']='us-west-1'

default['semaphore']['sleep_create_bucket_seconds']=3
default['semaphore']['sleep_delete_bucket_seconds']=10
default['semaphore']['sleep_wait_service_seconds']=30
default['semaphore']['sleep_wait_bootrap_seconds']=60
default['semaphore']['sleep_bootstrap']=2
default['semaphore']['create_bucket']['timeout']=2
default['semaphore']['write_object']['timeout']=2

default['semaphore']['s3_bucket_name']="starting-instance"
default['semaphore']['s3_bucket_name_done']="starting-instance-done"

default['semaphore']['service_url']='http://localhost:8070/alfresco'
default['semaphore']['service_accepted_responses']=%w(302 200)
default['semaphore']['parallel']=false
default['semaphore']['bootstrapped_key']='done'

default['semaphore']['s3_bucket_done']['force_creation']=false
default['semaphore']['wait_while_service_up']['force_wait']=false
```

Main attributes are:

- **['semaphore']['aws_region']** region where buckets are created, it is strictly recommendable to use us-west-1 to use some mechanisms available just on that region
- **['semaphore']['s3_bucket_name']** bucket name used as lock to notify an instance is starting. This bucket **MUST NOT exist on the account** and will be automatically crated by the semaphore
- **['semaphore']['s3_bucket_name_done']** bucket name used to notify an instance already bootstrapped. If this bucket does not exists it's possible force its creation in the semaphore setting **['s3_bucket_done']['force_creation'] = true**
- **['semaphore']['service_url']** url of the Alfresco instance we want to wait to start. If using the `chef-alfresco` cookbook it's possible to set it as
`default['semaphore']['service_url'] = "#{node['alfresco']['internal_protocol']}://#{node['alfresco']['internal_hostname']}:#{node['alfresco']['repo_tomcat_instance']['port']}/#{node['alfresco']['properties']['alfresco.context']}"`
- **['semaphore']['parallel']** set to true to use the parallel logic
- **['semaphore']['wait\_while_service\_up']['force_wait']** set to true if each node will need to wait alfresco service to be up (used just in parallel mode)

## Custom Chef Resources

### Logstash EC2 Discovery

## Recipe wrappers

### AWS Commandline client
### Chef Zero
### Databags to Files
### EC2 Tagging

## Cookbook lifecycle

### Run release
### Run tests

#### Run tests on AWS using kitchen-ec2 driver
- Install the [AWS command line tools](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html)
- Run [aws configure](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) to place your AWS credentials on the drive at ~/.aws/credentials.
- Create your AWS SSH key. Below an e example using your name:
`aws ec2 create-key-pair --key-name $USER | ruby -e "require 'json'; puts JSON.parse(STDIN.read)['KeyMaterial']" > ~/.ssh/$USER`
- set the access permissions to 400
`chmod 400 ~/.ssh/$USER`
- install ec2 gem
`gem install ec2`
- Modify the following values in .kitchen.ec2.yml:
>   **driver**

    `aws_ssh_key_id`: use the key id used to create the key at step 3

    `region`: use the one you need

    `availability_zone`: use the one you need

    `require_chef_omnibus`: use the one you need

    `subnet_id`: use the one you need

    `instance_type`: use the one you need

    `associate_public_ip`: use the one you need

    `shared_credentials_profile`: use the one you need

    `vpc_id`: use the one you need

>   **transport**

   `ssh_key`: use the path of your key

   `username`: username to access the instance

>   **platforms driver**

	`image_id`: use the image id you need

	`[tags] Name`: Name of the AWS instance

-  Modify `aws_access_key_id` and `aws_access_access_key` in **test/integration/data_bags/aws/test.json** with the ones of the aws account in use
- `export KITCHEN_YAML=./.kitchen.ec2.yml` to use the ec2 kitchen yml instead of the default one (*.kitchen.yml*)
- `kitchen create <suite_name>` to create the aws instance
- `kitchen verify <suite_name>` to run the tests on the created one
- `kitchen destroy <suite_name>` to terminate the aws instance

More Info: [kitchen-ec2](https://github.com/test-kitchen/kitchen-ec2)

#### Testing the parallel semaphore with kitchen ec2

Example staring 4 nodes with kitchen ec2:

- follow the previous section to modify any required parameter to AWS
- open 4 terminal windows
- on each terminal

`export KITCHEN_YAML=./.kitchen.ec2.yml`

`kitchen create ec2-parallel-node<n>`

   where n is from 1 to 4

- once creation is completed on the 4 terminal windows run at the same time

  `kitchen converge ec2-parallel-node<n>`

  where n is from 1 to 4

Example logs from first node bootstrapping

```
Recipe: commons::start_instance
  * ruby_block[start-instance] action run[Semaphore][start_parallel] Start Parallel
Forcing creation of bucket ec2-kitchen-bucketname-done-parallel-todelete
[Semaphore][create_bucket] Creating bucket ec2-kitchen-bucketname-done-parallel-todelete
[Semaphore][create_bucket] Bucket ec2-kitchen-bucketname-done-parallel-todelete created!
[Semaphore][bootstrapped?]           done does not exist in ec2-kitchen-bucketname-done-parallel-todelete -> No instance bootstrapped
[Semaphore][create_bucket] Creating bucket ec2-kitchen-bucketname-parallel-todelete
[Semaphore][create_bucket] Bucket ec2-kitchen-bucketname-parallel-todelete created!
[Semaphore][start_parallel] bucket created -> exit

    - execute the ruby block start-instance
Recipe: commons::wait_instance
  * ruby_block[wait-instance] action run[Semaphore][wait_while_service_up_parallel] Wait While Service Up Parallel
[Semaphore][wait_while_service_up_parallel] force wait: true
[Semaphore][wait_while_service_up] Checking if [http://httpstat.us/404] is up
[Semaphore][wait_while_service_up] Attempt #0
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Attempt #1
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Attempt #2
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Attempt #3
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Attempt #4
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Max number retry reached

    - execute the ruby block wait-instance
Recipe: commons::stop_instance
  * ruby_block[stop-instance] action run[Semaphore][stop_parallel] Stop Parallel
[Semaphore][bootstrapped?]           done does not exist in ec2-kitchen-bucketname-done-parallel-todelete -> No instance bootstrapped
[Semaphore][stop_parallel] No instance bootstrapped yet!
[Semaphore][write_object] Writing Object
[Semaphore][write_object] Writing Object done in bucket ec2-kitchen-bucketname-done-parallel-todelete
[Semaphore][write_object] Object in bucket!
[Semaphore][stop] Deleting bucket ec2-kitchen-bucketname-parallel-todelete
[Semaphore][stop] Bucket ec2-kitchen-bucketname-parallel-todelete deleted!
```  
Example logs from second node bootstrapping after the first

```
Recipe: commons::start_instance
* ruby_block[start-instance] action run[Semaphore][start_parallel] Start Parallel
Forcing creation of bucket ec2-kitchen-bucketname-done-parallel-todelete
[Semaphore][create_bucket] Creating bucket ec2-kitchen-bucketname-done-parallel-todelete
[Semaphore][create_bucket] Bucket ec2-kitchen-bucketname-done-parallel-todelete already exists
[Semaphore][create_bucket] Your previous request to create the named bucket succeeded and you already own it.
[Semaphore][bootstrapped?]    done does not exist in ec2-kitchen-bucketname-done-parallel-todelete -> No instance bootstrapped
[Semaphore][create_bucket] Creating bucket ec2-kitchen-bucketname-parallel-todelete
[Semaphore][create_bucket] Bucket ec2-kitchen-bucketname-parallel-todelete already exists
[Semaphore][create_bucket] Your previous request to create the named bucket succeeded and you already own it.
[Semaphore][start_parallel] bucket not created -> waiting bootstrap
[Semaphore][wait_while_bootrapped] Attempt[0] to check node bootstrapped
[Semaphore][bootstrapped?]    done does not exist in ec2-kitchen-bucketname-done-parallel-todelete -> No instance bootstrapped
[Semaphore][wait_while_bootrapped] Attempt[1] to check node bootstrapped
[Semaphore][bootstrapped?]    done does not exist in ec2-kitchen-bucketname-done-parallel-todelete -> No instance bootstrapped
[Semaphore][wait_while_bootrapped] Attempt[2] to check node bootstrapped
[Semaphore][bootstrapped?]    done does not exist in ec2-kitchen-bucketname-done-parallel-todelete -> No instance bootstrapped
[Semaphore][wait_while_bootrapped] Attempt[3] to check node bootstrapped
[Semaphore][bootstrapped?] An instance alredy bootstrapped!
[Semaphore][wait_while_bootrapped] Instance Bootstrapped!

    - execute the ruby block start-instance
Recipe: commons::wait_instance
  * ruby_block[wait-instance] action run[Semaphore][wait_while_service_up_parallel] Wait While Service Up Parallel
[Semaphore][wait_while_service_up_parallel] force wait: true
[Semaphore][wait_while_service_up] Checking if [http://httpstat.us/404] is up
[Semaphore][wait_while_service_up] Attempt #0
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Attempt #1
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Attempt #2
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Attempt #3
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Attempt #4
[Semaphore][wait_while_service_up] [404] http://httpstat.us/404 not available yet - sleep 30 seconds
[Semaphore][wait_while_service_up] Max number retry reached

    - execute the ruby block wait-instance
Recipe: commons::stop_instance
  * ruby_block[stop-instance] action run[Semaphore][stop_parallel] Stop Parallel
[Semaphore][bootstrapped?] An instance alredy bootstrapped!
[Semaphore][stop_parallel] An instance already bootstrapped!
[Semaphore][write_object] Writing Object
[Semaphore][write_object] Writing Object i-fa9b1a69 in bucket ec2-kitchen-bucketname-done-parallel-todelete
[Semaphore][write_object] Object in bucket!
[Semaphore][stop] Deleting bucket ec2-kitchen-bucketname-parallel-todelete
[Semaphore][stop] No such bucket to delete -> exit

```

### .... from packer-common
