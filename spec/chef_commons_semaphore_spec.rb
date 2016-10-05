describe InstanceSemaphore do

  let(:dummy_instancesemaphore) { Class.new { include InstanceSemaphore } }


  describe '#start' do
    #let(:mynode) {Class.new {Chef::Node}}
    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['hostname']='127.0.0.1'
      @mynode.default['semaphore']['s3_bucket_name']='Bucket-Name-test'
      @mynode.default['semaphore']['sleep_create_bucket_seconds']=3
      @mynode.default['semaphore']['aws_region']='us-east-1'
      @mynode.default['semaphore']['max_retry_count']=2
    end

    context 'when it CAN create the bucket' do
      it 'returns true' do
        expect(dummy_instancesemaphore.new.start(@mynode)).to eq(true)
      end
    end

    context 'when it CANNOT create the bucket' do
      it 'returs false' do

      Aws.config[:s3] = {
            stub_responses: {
                create_bucket: Aws::S3::Errors::BucketAlreadyOwnedByYou.new(
                "Your previous request to create the named bucket succeeded and you already own it",
                "Your previous request to create the named bucket succeeded and you already own it"
                )
              }
            }
       expect(dummy_instancesemaphore.new.start(@mynode)).to eq(false)
      end
    end

    context 'when it is not a valid bucket name' do
      it 'returs false' do

      Aws.config[:s3] = {
            stub_responses: {
                create_bucket: Aws::S3::Errors::InvalidBucketName.new(
                "Invalid bucket name",
                "Invalid bucket name"
                )
              }
            }
       expect(dummy_instancesemaphore.new.start(@mynode)).to eq(false)
      end
    end


  end

  describe '#wait_while_service_up' do
    let(:response302)    { double(:response, code: '302', body: 'Found') }
    let(:response200)    { double(:response, code: '200', body: 'OK') }
    let(:response404)    { double(:response, code: '404', body: 'Not Found') }

    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['hostname']='127.0.0.1'
      @mynode.default['semaphore']['max_retry_count']=2
      @mynode.default['semaphore']['service_url']='http://localhost:8070/alfresco'
      @mynode.default['semaphore']['sleep_wait_service_seconds']=2
      @mynode.default['semaphore']['service_accepted_responses']=%w(302 200)
    end


    context 'when the response code is 302' do
      it 'returns true' do
        allow(Net::HTTP).to receive(:get_response).and_return(response302)
        expect(dummy_instancesemaphore.new.wait_while_service_up(@mynode)).to eq(true)
      end
    end

    context 'when the response code is 200' do
      it 'returns true' do
        allow(Net::HTTP).to receive(:get_response).and_return(response200)
        expect(dummy_instancesemaphore.new.wait_while_service_up(@mynode)).to eq(true)
      end
    end

    context 'when the response code is 404' do
      it 'returns false' do
        allow(Net::HTTP).to receive(:get_response).and_return(response404)
        expect(dummy_instancesemaphore.new.wait_while_service_up(@mynode)).to eq(false)
      end
    end

    context 'when a network exception is hit' do
      it 'returns false' do
        allow(Net::HTTP).to receive(:get_response).and_raise(Net::HTTPBadResponse)
        expect(dummy_instancesemaphore.new.wait_while_service_up(@mynode)).to eq(false)
      end
    end
  end

  describe '#stop' do
    #let(:mynode) {Class.new {Chef::Node}}
    before(:all) do
      @mynode = Chef::Node.new
      @mynode.default['hostname']='127.0.0.1'
      @mynode.default['semaphore']['s3_bucket_name']='bucket-name-test'
      @mynode.default['semaphore']['sleep_delete_bucket_seconds']=3
      @mynode.default['semaphore']['aws_region']='us-east-1'
      @mynode.default['semaphore']['max_retry_count']=2
    end

    context 'when it CAN delete the bucket' do
      it 'returns true' do
        expect(dummy_instancesemaphore.new.stop(@mynode)).to eq(true)
      end
    end

    context 'when the bucket does not exist' do
      it 'returns true' do

        Aws.config[:s3] = {
          stub_responses: {
              delete_bucket: Aws::S3::Errors::NoSuchBucket.new(
              "The specified bucket does not exist",
              "The specified bucket does not exist"
              )
            }
        }

        expect(dummy_instancesemaphore.new.stop(@mynode)).to eq(true)
      end
    end

    context 'when it always hit Aws::S3::Errors::ServiceError ' do
      it 'it throws an exception' do

        Aws.config[:s3] = {
          stub_responses: {
              delete_bucket: Aws::S3::Errors::ServiceError.new("ServiceError",
                "ServiceError")
            }
        }
        expect(dummy_instancesemaphore.new.stop(@mynode)).to eq(false)
      end
    end

  end

end
