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
        File.open( "#{@appliance_xml_file}.vmx-input", 'w' ) {|f| f.write( doc ) }
      end      

      file appliance_vmx_package => [ "#{@appliance_xml_file}.vmx-input" ] do
        execute_command( "virt-pack -o $PWD/#{@build_dir}/appliances/#{@arch} #{@appliance_xml_file}.vmx-input" )
      end

      super_simple_name = File.basename( @simple_name, '-appliance' )
      desc "Build #{super_simple_name} appliance for VMware"
      task "appliance:#{@simple_name}:vmx" => [ appliance_vmx_package ]
    end

  end
end
