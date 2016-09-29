# chef-commons
A collection of Chef libraries, custom resources, (recipe) wrappers and other useful tools used to manage Chef cookbook lifecycle.

## Chef libraries

### EC2 Discovery

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

More Info:

- [https://github.com/test-kitchen/kitchen-ec2](https://github.com/test-kitchen/kitchen-ec2)
-   

### .... from packer-common
