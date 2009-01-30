require 'rake/tasklib'
require 'rexml/document'

module JBossCloud

  class ApplianceVMXImage < Rake::TaskLib

    def initialize(build_dir, appliance_xml_file, version, release, arch)
      @build_dir        = build_dir
      @appliance_xml_file   = appliance_xml_file
      @simple_name = File.basename( appliance_xml_file, '.xml' )
      @version = version
      @release = release
      @arch = arch
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

      file "#{@appliance_xml_file}.vmx-input" => [ @appliance_xml_file ] do
        doc = REXML::Document.new( File.read( @appliance_xml_file ) )
        name_elem = doc.root.elements['name']
        name_elem.attributes[ 'version' ] = "#{@version}-#{@release}"
        description_elem = doc.root.elements['description']
        if ( description_elem.nil? )
          description_elem = REXML::Element.new( "description" )
          description_elem.text = "#{@simple_name} Appliance\n Version: #{@version}-#{@release}"
          doc.root.insert_after( name_elem, description_elem )
        end
        # update xml the file according to selected build architecture
        arch_elem = doc.elements["//arch"]
        arch_elem.text = @arch
        File.open( "#{@appliance_xml_file}.vmx-input", 'w' ) {|f| f.write( doc ) }
      end
      
      #desc "Build #{super_simple_name} appliance for VMware personal environments (Server/Workstation/Fusion)"
      task "appliance:#{@simple_name}:vmware:personal" => [ "#{@appliance_xml_file}.vmx-input" ] do
        FileUtils.mkdir_p vmware_personal_output_folder       

        if ( !File.exists?( vmware_personal_vmx_file ) || File.new( "#{@appliance_xml_file}.vmx-input" ).mtime > File.new( vmware_personal_vmx_file ).mtime  )
          execute_command( "#{Dir.pwd}/lib/python-virtinst/virt-convert -o vmx -D vmdk #{@appliance_xml_file}.vmx-input #{vmware_personal_output_folder}/" )
        end
      end

      #desc "Build #{super_simple_name} appliance for VMware enterprise environments (ESX/ESXi)"
      task "appliance:#{@simple_name}:vmware:enterprise" => [ "appliance:#{@simple_name}:vmware:personal" ] do
        FileUtils.mkdir_p vmware_enterprise_output_folder

        # copy RAW disk to VMware enterprise destination folder
        FileUtils.cp( File.dirname( @appliance_xml_file ) + "/#{@simple_name}-sda.raw", vmware_enterprise_output_folder + "/#{@simple_name}-sda.raw" )

        vmx_data = File.open( vmware_personal_vmx_file ).readlines
        
        vmx_data.map! do |line|
          # replace guestOS informations to: other26xlinux or other26xlinux-64, this seems to be the savests values (tm)
          line = line.gsub(/guestOS = (.*)/, "guestOS = #{@arch == "x86_64" ? "other26xlinux-64" : "other26xlinux"}")

          # replace IDE disk with SCSI, it's recommended for workstation and required for ESX
          line = line.gsub(/ide0:0/, "scsi0:0")
        end

        # yes, we want a SCSI controller because we have SCSI disks!
        vmx_data += ["scsi0.present = \"true\""] unless vmx_data.grep(/scsi0.present = "true"/).length  > 0
        vmx_data += ["scsi0.virtualDev = \"lsilogic\""] unless vmx_data.grep(/scsi0.virtualDev = "lsilogic"/).length  > 0

        # write changes to file
        File.new( vmware_enterprise_vmx_file , "w+" ).puts( vmx_data )

        # create new VMDK descriptor file
        vmdk_descriptor_file_name = vmware_enterprise_output_folder + "/#{@simple_name}-sda.vmdk"

        vmdk_file = File.new( vmdk_descriptor_file_name, "w+" )

        vmdk_file.puts("# Disk DescriptorFile")
        vmdk_file.puts("version=1")
        vmdk_file.puts("CID=af54a9d2")
        vmdk_file.puts("parentCID=ffffffff")
        vmdk_file.puts("createType=\"vmfs\"")

        vmdk_file.puts("")

        vmdk_file.puts("# Extent description")
        # todo: read from kickstart file disk size and put appropriate value after RW:
        vmdk_file.puts("RW 4194304 VMFS \"#{@simple_name}-sda.raw\"")

        vmdk_file.puts("")

        vmdk_file.puts("# The Disk Data Base")
        vmdk_file.puts("#DDB")

        vmdk_file.puts("")

        # todo: update these values according to disk size change
        vmdk_file.puts("ddb.toolsVersion = \"0\"")
        vmdk_file.puts("ddb.adapterType = \"lsilogic\"")
        vmdk_file.puts("ddb.geometry.sectors = \"63\"")
        vmdk_file.puts("ddb.geometry.heads = \"255\"")
        vmdk_file.puts("ddb.geometry.cylinders = \"261\"")
        vmdk_file.puts("ddb.encoding = \"UTF-8\"")
        vmdk_file.puts("ddb.virtualHWVersion = \"4\"")

        # don't know if this is required, for now - commented
        #ddb.uuid = "60 00 C2 97 c7 af 99 c5-bc d9 2a eb 9c 7b 66 10"

      end

      desc "Build #{super_simple_name} appliance for VMware"
      task "appliance:#{@simple_name}:vmware" => [ "appliance:#{@simple_name}:vmware:enterprise" ]
    end
  end
end
