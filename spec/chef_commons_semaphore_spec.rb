describe InstanceSemaphore do
  let(:dummy_instancesemaphore) { Class.new { include InstanceSemaphore } }

  describe '#start' do
    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['hostname'] = '127.0.0.1'
      @mynode.default['semaphore']['s3_bucket_lock']['name'] = 'Bucket-Name-test'
      @mynode.default['semaphore']['sleep_create_bucket_seconds'] = 1
      @mynode.default['semaphore']['s3_bucket_lock']['aws_region'] = 'us-east-1'
      @mynode.default['semaphore']['max_retry_count'] = 2
    end

    context 'when it CAN create the bucket' do
      it 'returns true' do
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:sleep)
        res = semaphore.start(@mynode)
        expect(res).to eq(true)
      end
    end

    context 'when it CANNOT create the bucket' do
      it 'calls sleep and returns false' do
        Aws.config[:s3] = {
          stub_responses: {
            create_bucket: Aws::S3::Errors::BucketAlreadyOwnedByYou.new(
              'Your previous request to create the named bucket succeeded and you already own it',
              'Your previous request to create the named bucket succeeded and you already own it'
            )
          }
        }
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).to receive(:sleep).with(@mynode['semaphore']['sleep_create_bucket_seconds']).exactly(@mynode['semaphore']['max_retry_count']).times
        expect(semaphore.start(@mynode)).to eq(false)
      end
    end

    context 'when it is not a valid bucket name' do
      it 'does not call sleep and returns false' do
        Aws.config[:s3] = {
          stub_responses: {
            create_bucket: Aws::S3::Errors::InvalidBucketName.new(
              'Invalid bucket name', 'Invalid bucket name'
            )
          }
        }
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.start(@mynode)).to eq(false)
      end
    end
  end

  describe '#wait_while_service_up' do
    let(:response302)    { double(:response, code: '302', body: 'Found') }
    let(:response200)    { double(:response, code: '200', body: 'OK') }
    let(:response404)    { double(:response, code: '404', body: 'Not Found') }

    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['hostname'] = '127.0.0.1'
      @mynode.default['semaphore']['max_retry_count'] = 2
      @mynode.default['semaphore']['service_url'] = 'http://localhost:8070/alfresco'
      @mynode.default['semaphore']['sleep_wait_service_seconds'] = 1
      @mynode.default['semaphore']['service_accepted_responses'] = %w(302 200)
    end

    context 'when the response code is 302' do
      it 'does not call sleep and returns true' do
        allow(Net::HTTP).to receive(:get_response).and_return(response302)
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.wait_while_service_up(@mynode)).to eq(true)
      end
    end

    context 'when the response code is 200' do
      it 'does not call sleep and returns true' do
        allow(Net::HTTP).to receive(:get_response).and_return(response200)
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.wait_while_service_up(@mynode)).to eq(true)
      end
    end

    context 'when the response code is 404' do
      it 'calls sleep and returns false' do
        allow(Net::HTTP).to receive(:get_response).and_return(response404)
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).to receive(:sleep).with(
          @mynode['semaphore']['sleep_wait_service_seconds']).exactly(@mynode['semaphore']['max_retry_count']).times
        expect(semaphore.wait_while_service_up(@mynode)).to eq(false)
      end
    end

    context 'when a network exception is hit' do
      it 'does NOT call sleep and returns false' do
        allow(Net::HTTP).to receive(:get_response).and_raise(Net::HTTPBadResponse)
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.wait_while_service_up(@mynode)).to eq(false)
      end
    end
  end

  describe '#create_bucket' do
    before(:all) do
      @region = 'us-east-1'
    end

    context 'when it can create the bucket' do
      it 'does NOT call sleep and returns true' do
        Aws.config[:s3] = {
          stub_responses: {
            create_bucket: Aws::S3::Types::CreateBucketOutput.new
          }
        }
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.create_bucket(@region, 'test1', 2, 1)).to eq(true)
      end
    end

    context 'when it CANNOT create the bucket' do
      it 'does not call sleep and returns false' do
        semaphore = dummy_instancesemaphore.new
        Aws.config[:s3] = {
          stub_responses: {
            create_bucket: Aws::S3::Errors::BucketAlreadyOwnedByYou.new(
              'Your previous request to create the named bucket succeeded and you already own it',
              'Your previous request to create the named bucket succeeded and you already own it'
            )
          }
        }
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.create_bucket(@region, 'test2', 2, 1)).to eq(false)
      end
    end

    context 'when it is not a valid bucket name' do
      it 'does not call sleep and returns false' do
        semaphore = dummy_instancesemaphore.new
        Aws.config[:s3] = {
          stub_responses: {
            create_bucket:  Aws::S3::Errors::InvalidBucketName.new(
              'Invalid bucket name', 'Invalid bucket name'
            )
          }
        }
        expect(semaphore).not_to receive(:sleep)
        expect { semaphore.create_bucket(@region, 'test3', 2, 1) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#bootstrapped?' do
    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['hostname'] = '127.0.0.1'
      @mynode.default['semaphore']['sleep_bootstrap'] = 1
      @mynode.default['semaphore']['s3_bucket_lock']['aws_region'] = 'us-east-1'
      @mynode.default['semaphore']['max_retry_count'] = 2
      @mynode.default['semaphore']['s3_bucket_done']['name'] = 'bucket-name-test-done'
      @mynode.default['semaphore']['s3_bucket_done']['aws_region'] = 'us-west-1'
      @mynode.default['semaphore']['bootstrapped_key'] = 'my-key'
    end

    context 'when it finds the object into the bucket' do
      it 'does not call sleep and returns true' do
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.bootstrapped?(@mynode)).to eq(true)
      end
    end

    context 'when it can\'t find the object into the bucket' do
      it 'does not call sleep and returns false' do
        Aws.config[:s3] = {
          stub_responses: {
            get_object: Aws::S3::Errors::NoSuchKey.new(
              'No Such Key', 'No Such Key'
            )
          }
        }
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.bootstrapped?(@mynode)).to eq(false)
      end
    end

    context 'when it throws any other exception' do
      it 'calls sleep and returns false' do
        Aws.config[:s3] = {
          stub_responses: {
            get_object:  Aws::S3::Errors::ServiceError.new(
              'Error', 'Error'
            )
          }
        }
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).to receive(:sleep).with(@mynode['semaphore']['sleep_bootstrap']).exactly(@mynode['semaphore']['max_retry_count']).times
        expect(semaphore.bootstrapped?(@mynode)).to eq(false)
      end
    end
  end

  describe '#wait_while_bootrapped' do
    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['semaphore']['sleep_wait_bootrap_seconds'] = 1
      @mynode.default['semaphore']['sleep_bootstrap'] = 1
      @mynode.default['semaphore']['s3_bucket_lock']['aws_region'] = 'us-east-1'
      @mynode.default['semaphore']['max_retry_count'] = 3
      @mynode.default['semaphore']['s3_bucket_done']['name'] = 'bucket-name-test-done'
      @mynode.default['semaphore']['bootstrapped_key'] = 'my-key'
      @mynode.default['semaphore']['create_bucket']['timeout'] = 1
      @mynode.default['semaphore']['s3_bucket_done']['force_creation'] = false
    end

    context 'when it\'s bootsrapped' do
      it 'does not call sleep nor create_bucket and returns true' do
        semaphore = dummy_instancesemaphore.new
        allow(semaphore).to receive(:bootstrapped?).and_return(true)
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore).not_to receive(:create_bucket)
        expect(semaphore.wait_while_bootrapped(@mynode)).to eq(true)
      end
    end

    context 'when it\'s not bootsrapped' do
      it 'calls sleep, does not call create_bucket and returns false' do
        semaphore = dummy_instancesemaphore.new
        allow(semaphore).to receive(:bootstrapped?).and_return(false)
        expect(semaphore).not_to receive(:create_bucket)
        expect(semaphore).to receive(:sleep).with(@mynode['semaphore']['sleep_bootstrap']).exactly(@mynode['semaphore']['max_retry_count']).times
        expect(semaphore.wait_while_bootrapped(@mynode)).to eq(false)
      end
    end

    context 'when force_creation is true' do
      it 'tries to create the bucket' do
        semaphore = dummy_instancesemaphore.new
        @mynode.default['semaphore']['s3_bucket_done']['force_creation'] = true
        allow(semaphore).to receive(:bootstrapped?).and_return(true)
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.wait_while_bootrapped(@mynode)).to eq(true)
      end
    end
  end

  describe '#start_parallel' do
    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['semaphore']['sleep_wait_bootrap_seconds'] = 1
      @mynode.default['semaphore']['sleep_bootstrap'] = 1
      @mynode.default['semaphore']['s3_bucket_lock']['aws_region'] = 'us-east-1'
      @mynode.default['semaphore']['max_retry_count'] = 3
      @mynode.default['semaphore']['s3_bucket_done']['name'] = 'bucket-name-test-done'
      @mynode.default['semaphore']['bootstrapped_key'] = 'my-key'
      @mynode.default['semaphore']['create_bucket']['timeout'] = 1
      @mynode.default['semaphore']['s3_bucket_done']['force_creation'] = false
    end

    context 'when it\'s bootsrapped' do
      it 'returns true' do
        semaphore = dummy_instancesemaphore.new
        allow(semaphore).to receive(:bootstrapped?).and_return(true)
        expect(semaphore.start_parallel(@mynode)).to eq(true)
      end
    end

    context 'when it\'s not bootsrapped' do
      it 'returns false' do
        semaphore = dummy_instancesemaphore.new
        allow(semaphore).to receive(:bootstrapped?).and_return(false)
        allow(semaphore).to receive(:create_bucket).and_return(true)
        expect(semaphore).not_to receive(:sleep)
        expect(semaphore.start_parallel(@mynode)).to eq(true)
      end
    end

    context 'when it\'s not bootsrapped and cannot create the bucket' do
      it 'returns false' do
        semaphore = dummy_instancesemaphore.new
        allow(semaphore).to receive(:bootstrapped?).and_return(false)
        allow(semaphore).to receive(:create_bucket).and_return(false)
        allow(semaphore).to receive(:wait_while_bootrapped).and_return(true)
        expect(semaphore.start_parallel(@mynode)).to eq(true)
      end
    end

    context 'when it\'s not bootsrapped and cannot create the bucket and fails to wait node to bootstrap' do
      it 'returns false' do
        semaphore = dummy_instancesemaphore.new
        allow(semaphore).to receive(:bootstrapped?).and_return(false)
        allow(semaphore).to receive(:create_bucket).and_return(false)
        allow(semaphore).to receive(:wait_while_bootrapped).and_return(false)
        expect(semaphore.start_parallel(@mynode)).to eq(false)
      end
    end
  end

  describe '#wait_while_service_up_parallel' do
    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['semaphore']['sleep_wait_bootrap_seconds'] = 1
      @mynode.default['semaphore']['sleep_bootstrap'] = 1
      @mynode.default['semaphore']['s3_bucket_lock']['aws_region'] = 'us-east-1'
      @mynode.default['semaphore']['max_retry_count'] = 3
      @mynode.default['semaphore']['s3_bucket_done']['name'] = 'bucket-name-test-done'
      @mynode.default['semaphore']['bootstrapped_key'] = 'my-key'
      @mynode.default['semaphore']['create_bucket']['timeout'] = 1
    end

    context 'when it\'s forced to wait' do
      it 'receives wait_while_service_up and returns true' do
        @mynode.default['semaphore']['wait_while_service_up']['force_wait'] = true
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).to receive(:wait_while_service_up).with(@mynode).and_return(true)
        expect(semaphore).not_to receive(:bootstrapped?)
        res = semaphore.wait_while_service_up_parallel(@mynode)
        expect(res).to eq(true)
      end
    end

    context 'when it\'s not forced to wait and it has not bootstrapped' do
      it 'receives wait_while_service_up and returns true' do
        @mynode.default['semaphore']['wait_while_service_up']['force_wait'] = false
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).to receive(:wait_while_service_up).with(@mynode).and_return(true)
        allow(semaphore).to receive(:bootstrapped?).and_return(false)
        res = semaphore.wait_while_service_up_parallel(@mynode)
        expect(res).to eq(true)
      end
    end

    context 'when it\'s not forced to wait and has bootstrapped' do
      it 'does not receives wait_while_service_up and returns true' do
        @mynode.default['semaphore']['wait_while_service_up']['force_wait'] = false
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:wait_while_service_up)
        allow(semaphore).to receive(:bootstrapped?).and_return(true)
        res = semaphore.wait_while_service_up_parallel(@mynode)
        expect(res).to eq(true)
      end
    end
  end

  describe '#stop_parallel' do
    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['semaphore']['sleep_wait_bootrap_seconds'] = 1
      @mynode.default['semaphore']['sleep_bootstrap'] = 1
      @mynode.default['semaphore']['s3_bucket_lock']['aws_region'] = 'us-east-1'
      @mynode.default['hostname'] = 'localhost'
      @mynode.default['semaphore']['max_retry_count'] = 3
      @mynode.default['semaphore']['s3_bucket_done']['name'] = 'bucket-name-test-done'
      @mynode.default['semaphore']['s3_bucket_done']['aws_region'] = 'us-west-1'
      @mynode.default['semaphore']['bootstrapped_key'] = 'my-key'
      @mynode.default['semaphore']['create_bucket']['timeout'] = 1
      @mynode.default['semaphore']['write_object']['timeout'] = 1
      @mynode.default['ec2']['instance_id'] = 'i-213123'
    end

    context 'when it\'s bootstrapped' do
      it 'receives stop and write_object' do
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).to receive(:write_object).with(@mynode['semaphore']['s3_bucket_done']['aws_region'],
        @mynode['semaphore']['s3_bucket_done']['name'],
        @mynode['ec2']['instance_id'],
        "Bootrapped instance_id: #{@mynode['ec2']['instance_id']}",
        @mynode['semaphore']['write_object']['timeout'],
        @mynode['semaphore']['max_retry_count'])
        expect(semaphore).to receive(:stop)
        allow(semaphore).to receive(:bootstrapped?).and_return(true)
        semaphore.stop_parallel(@mynode)
      end
    end

    context 'when it\'s not bootstrapped' do
      it 'receives stop and write_object' do
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).to receive(:write_object).with(@mynode['semaphore']['s3_bucket_done']['aws_region'],
        @mynode['semaphore']['s3_bucket_done']['name'],
        @mynode['semaphore']['bootstrapped_key'],
        "Bootrapped instance_id: #{@mynode['ec2']['instance_id']}",
        @mynode['semaphore']['write_object']['timeout'],
        @mynode['semaphore']['max_retry_count'])
        expect(semaphore).to receive(:stop)
        allow(semaphore).to receive(:bootstrapped?).and_return(false)
        semaphore.stop_parallel(@mynode)
      end
    end
  end

  describe '#write_object' do
    before(:all) do
      @region = 'us-east-1'
      @s3_bucket_name = 'bucket-name'
      @object_name = 'object-name'
      @body = 'body test'
      @timeout = 1
      @retries = 2
    end

    context 'when it can post the object' do
      it 'returns true' do
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).not_to receive(:sleep)
        res = semaphore.write_object(@region,
        @s3_bucket_name,
        @object_name,
        @body,
        @timeout,
        @retries)
        expect(res).to eq(true)
      end
    end

    context 'when it cannot post the object' do
      it 'returns false' do
        Aws.config[:s3] = {
          stub_responses: {
            put_object: Aws::S3::Errors::NoSuchBucket.new(
              'The specified bucket does not exist',
              'The specified bucket does not exist'
            )
          }
        }
        semaphore = dummy_instancesemaphore.new
        expect(semaphore).to receive(:sleep).with(1).exactly(@retries).times
        res = semaphore.write_object(@region,
        @s3_bucket_name,
        @object_name,
        @body,
        @timeout,
        @retries)
        expect(res).to eq(false)
      end
    end
  end
end
