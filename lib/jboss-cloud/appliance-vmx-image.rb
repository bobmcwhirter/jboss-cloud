require 'rake/tasklib'
require 'rexml/document'

module JBossCloud

  class ApplianceVMXImage < Rake::TaskLib

    def initialize( appliance_xml_file )
      @appliance_xml_file   = appliance_xml_file
      @simple_name = File.basename( appliance_xml_file, '.xml' )

      define
    end

    def define
      define_precursors
    end

    def define_precursors

      super_simple_name = File.basename( @simple_name, '-appliance' )
      vmware_personal_output_folder = File.dirname( @appliance_xml_file ) + "/vmware/personal"
      vmware_personal_vmx_file = vmware_personal_output_folder + "/" + File.basename( @appliance_xml_file, ".xml" ) + '.vmx'
      vmware_enterprise_output_folder = File.dirname( @appliance_xml_file ) + "/vmware/enterprise"
      vmware_enterprise_vmx_file = vmware_enterprise_output_folder + "/" + File.basename( @appliance_xml_file, ".xml" ) + '.vmx'
      vmware_enterprise_vmdk_file = vmware_enterprise_output_folder + "/" + File.basename( @appliance_xml_file, ".xml" ) + '.vmdk'

      file "#{@appliance_xml_file}.vmx-input" => [ @appliance_xml_file ] do
        doc = REXML::Document.new( File.read( @appliance_xml_file ) )
        name_elem = doc.root.elements['name']
        name_elem.attributes[ 'version' ] = "#{JBossCloud::ImageBuilder.builder.config.version_with_release}"
        description_elem = doc.root.elements['description']
        if ( description_elem.nil? )
          description_elem = REXML::Element.new( "description" )
          description_elem.text = "#{@simple_name} Appliance\n Version: #{JBossCloud::ImageBuilder.builder.config.version_with_release}"
          doc.root.insert_after( name_elem, description_elem )
        end
        # update xml the file according to selected build architecture
        arch_elem = doc.elements["//arch"]
        arch_elem.text = JBossCloud::ImageBuilder.builder.config.build_arch
        File.open( "#{@appliance_xml_file}.vmx-input", 'w' ) {|f| f.write( doc ) }
      end

      desc "Build #{super_simple_name} appliance for VMware personal environments (Server/Workstation/Fusion)"
      task "appliance:#{@simple_name}:vmware:personal" => [ "#{@appliance_xml_file}.vmx-input" ] do
        FileUtils.mkdir_p vmware_personal_output_folder

        if ( !File.exists?( vmware_personal_vmx_file ) || File.new( "#{@appliance_xml_file}.vmx-input" ).mtime > File.new( vmware_personal_vmx_file ).mtime  )
          #execute_command( "#{Dir.pwd}/lib/python-virtinst/virt-convert -o vmx -D vmdk #{@appliance_xml_file}.vmx-input #{vmware_personal_output_folder}/" )
        end

        vmx_data = File.open( "src/base.vmx" ).read

        # replace version with current jboss cloud version
        vmx_data.gsub!( /#VERSION#/ , JBossCloud::ImageBuilder.builder.config.version_with_release )
        # change name
        vmx_data.gsub!( /#NAME#/ , @simple_name )
        # replace guestOS informations to: linux or otherlinux-64, this seems to be the savests values
        vmx_data.gsub!( /#GUESTOS#/ , "#{JBossCloud::ImageBuilder.builder.config.build_arch == "x86_64" ? "otherlinux-64" : "linux"}" )
        # disk filename must match
        vmx_data.gsub!(/#{@simple_name}.vmdk/, "#{@simple_name}-sda.vmdk")

        # todo: add support for select this while building appliance
        vmx_data += "\nethernet0.networkName = \"NAT\""

        # write changes to file
        File.new( vmware_personal_vmx_file , "w+" ).puts( vmx_data )
      end

      desc "Build #{super_simple_name} appliance for VMware enterprise environments (ESX/ESXi)"
      task "appliance:#{@simple_name}:vmware:enterprise" => [ @appliance_xml_file ] do
        FileUtils.mkdir_p vmware_enterprise_output_folder

        base_raw_file = File.dirname( @appliance_xml_file ) + "/#{@simple_name}-sda.raw"
        vmware_raw_file = vmware_enterprise_output_folder + "/#{@simple_name}-sda.raw"

        # copy RAW disk to VMware enterprise destination folder
        # todo: consider moving this file

        if ( !File.exists?( vmware_raw_file ) || File.new( base_raw_file ).mtime > File.new( vmware_raw_file ).mtime )
          FileUtils.cp( base_raw_file , vmware_enterprise_output_folder )
        end

        vmx_data = File.open( "src/base.vmx" ).read

        # replace version with current jboss cloud version
        vmx_data.gsub!( /#VERSION#/ , JBossCloud::ImageBuilder.builder.config.version_with_release )
        # replace name with current appliance name
        vmx_data.gsub!( /#NAME#/ , @simple_name )
        # replace guestOS informations to: other26xlinux or other26xlinux-64, this seems to be the savests values (tm)
        vmx_data.gsub!( /#GUESTOS#/ , "#{JBossCloud::ImageBuilder.builder.config.build_arch == "x86_64" ? "other26xlinux-64" : "other26xlinux"}" )
        # replace IDE disk with SCSI, it's recommended for workstation and required for ESX
        vmx_data.gsub!( /ide0:0/ , "scsi0:0" )

        # yes, we want a SCSI controller because we have SCSI disks!
        vmx_data += "\nscsi0.present = \"true\""
        vmx_data += "\nscsi0.virtualDev = \"lsilogic\""

        # todo: add support for select this while building appliance
        vmx_data += "\nethernet0.networkName = \"NAT\""

        # write changes to file
        File.new( vmware_enterprise_vmx_file , "w+" ).puts( vmx_data )

        vmdk_data = File.open( "src/base.vmdk" ).read
        vmdk_data.gsub!( /#NAME#/ , @simple_name )

        # todo: read from kickstart file disk size and put appropriate value after RW:
        # todo: update these values according to disk size change

        # create new VMDK descriptor file
        File.new( vmware_enterprise_vmdk_file, "w+" ).puts( vmdk_data )

      end

      #desc "Build #{super_simple_name} appliance for VMware"
      #task "appliance:#{@simple_name}:vmware" => [ "appliance:#{@simple_name}:vmware:personal", "appliance:#{@simple_name}:vmware:enterprise" ]
    end
  end
end
