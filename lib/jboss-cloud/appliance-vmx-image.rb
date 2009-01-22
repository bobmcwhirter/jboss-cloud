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
      appliance_vmx_package= "#{@build_dir}/appliances/#{@arch}/#{@simple_name}-#{@version}-#{@release}.#{@arch}.tgz"

      file "#{@appliance_xml_file}.vmx-input"=>[ @appliance_xml_file ] do
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
        abort
      end      

      file appliance_vmx_package => [ "#{@appliance_xml_file}.vmx-input" ] do
        #execute_command( "virt-pack -o $PWD/#{@build_dir}/appliances/#{@arch} #{@appliance_xml_file}.vmx-input" )
        
        vmx_file = File.dirname( @appliance_xml_file) + "/" + File.basename( @appliance_xml_file, ".xml" ) + '.vmx'
        execute_command( "#{Dir.pwd}/lib/python-virtinst/virt-convert -o vmx #{@appliance_xml_file}.vmx-input #{File.dirname( @appliance_xml_file)}/" ) unless ( File.exists?( vmx_file ) )
        
        if ( File.exists?( vmx_file ) )
          
          vmx_data = File.open( vmx_file).readlines

          vmx_data.map! do |line|
            # replace guestOS informations to: other26xlinux or other26xlinux-64, this seems to be the savests values (tm)
            line = line.gsub(/guestOS = (.*)/, "guestOS = #{@arch == "x86_64" ? "other26xlinux-64" : "other26xlinux"}")

            # replace IDE disk with SCSI, it's recommended (don't know about source, but it is)
            # IDE disks aren't working for ESXi, so we must have generated SCSI
            # changing only vmx file won't work because of 'IDE disk geometry' message after power on
            # currently commented out
            #
            # line = line.gsub(/ide0:0/, "scsi0:0")
          end

          # yes, we want a SCSI controller because we have SCSI disks!
          # vmx_data += ["scsi0.present = \"true\""] unless vmx_data.grep(/scsi0.present = "true"/).length  > 0
          # vmx_data += ["scsi0.virtualDev = \"lsilogic\""] unless vmx_data.grep(/scsi0.virtualDev = "lsilogic"/).length  > 0
          
          # write changes to file
          File.new( vmx_file , "w+" ).puts( vmx_data )
        end
      end

      super_simple_name = File.basename( @simple_name, '-appliance' )
      desc "Build #{super_simple_name} appliance for VMware"
      task "appliance:#{@simple_name}:vmx" => [ appliance_vmx_package ]
    end

  end
end
