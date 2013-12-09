require 'datagrid/helpers/table'
require 'datagrid/models/active_record_extension'
require 'datagrid/models/array_datagrid'

::ActiveRecord::Base.send :include, Datagrid::ActiveRecordExtension
