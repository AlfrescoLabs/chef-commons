# Below is an example on how to configure commons::databags-to-files recipe
#
# Configure file name and location
# default['commons']['databags_to_files']['default_destination_folder'] = "/etc/ssl/certs"
# default['commons']['databags_to_files']['default_filename_prefix'] = "mycertname"

# Configure databag my_certs_databag/test
# default['commons']['databags_to_files']['databags']['my_certs_databag']['test'] = {}

# filename_prefix is optional, if default_filename_prefix is set
# default['commons']['databags_to_files']['databags']['my_certs_databag']['test']['filename_prefix'] = 'myfilename'

# destination_folder is optional, if default_destination_folder is set
# default['commons']['databags_to_files']['databags']['my_certs_databag']['test']['destination_folder']
