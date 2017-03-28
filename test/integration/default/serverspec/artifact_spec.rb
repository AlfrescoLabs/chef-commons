require 'spec_helper'

describe 'maven_setup resource' do
  it 'should have installed maven' do
    expect(command('mvn -version').stdout).to match /Apache Maven/
  end

  it 'should have created a symlink to maven home' do
    expect(file('/usr/local/maven')).to be_symlink
  end

  it 'should have created the settings xml' do
    expect(file('/usr/local/maven/conf/settings.xml')).to exist
  end

  it 'created settings.xml should contain alfresco id' do
    expect(file('/usr/local/maven/conf/settings.xml')).to contain '<id>alfresco</id>'
  end
end

describe 'artifact resource' do
  it 'should have created file /home/vagrant/default_suite/junit1.jar' do
    expect(file('/home/vagrant/default_suite/junit1.jar')).to exist
  end

  it 'should have created folder /home/vagrant/subfolder_suite/junit3' do
    expect(file('/home/vagrant/subfolder_suite/junit3')).to be_directory
  end

  it "should only have created the META-INF dir \n  when setting subfolder property, thus \n  /home/vagrant/subfolder_suite/junit3/org" do
    expect(file('/home/vagrant/subfolder_suite/junit3/org')).not_to be_directory
  end

  it 'should not have created /home/vagrant/disabled_suite since this artifact is disabled' do
    expect(file('/home/vagrant/disabled_suite')).not_to exist
  end

  it 'should have created /home/vagrant/properties_suite' do
    expect(file('/home/vagrant/properties_suite')).to be_directory
  end

  it 'modified MANIFEST.MF to contain -> Manifest-Version:555' do
    expect(file('/home/vagrant/properties_suite/junit4/META-INF/MANIFEST.MF')).to contain 'Manifest-Version:555'
  end

  it 'modified LICENSE.txt to contain -> superProperty addition works?' do
    expect(file('/home/vagrant/properties_suite/junit4/LICENSE.txt')).to contain 'superProperty:addition works?'
  end

  it 'replaced term MANIFEST.MF to contain -> (Test replace Term)' do
    expect(file('/home/vagrant/properties_suite/junit4/META-INF/MANIFEST.MF')).to contain 'Created-By: 1.7.0_04-b20 (Test replace Term)'
  end
end
