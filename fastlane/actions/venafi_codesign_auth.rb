module Fastlane
  module Actions
    module SharedValues
      VENAFI_CODESIGN_CUSTOM_VALUE = :VENAFI_CODESIGN_CUSTOM_VALUE
    end

    class VenafiCodesignAuthAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        sh "tkdriverconfig getgrant --force --authurl=#{params[:tpp_url]}/vedauth --hsmurl=#{params[:tpp_url]}/vedhsm --username=#{params[:tpp_username]} --password=#{params[:tpp_password]}"
        sh "tkdriverconfig sync"
        #sh "codesign -v --force -o runtime -s \"#{params[:identity]}\" #{params[:app_path]}"
        #sh "tkdriverconfig revokegrant --force"
      end

      def self.description
        'Use Xcode codesign to sign an app using code signing certificates managed by Venafi CodeSign Protect.'
      end

      def self.details
        'Refer to Venafi CodeSign Protect MacOS keychain integration documentation to ensure pre-requisites have been met'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :tpp_url,
                                       # The name of the environment variable
                                       env_name: 'FL_TPP_URL',
                                       # a short description of this parameter
                                       description: 'Base URL for Venafi CodeSign Protect Platform',
                                       verify_block: proc do |value|
                                         unless value && !value.empty?
                                           UI.user_error!("No TPP URL for VenafiCodesignAction given, pass using `tpp_url: 'url'`")
                                         end
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :tpp_username,
                                      # The name of the environment variable
                                      env_name: 'FL_TPP_USERNAME',
                                      # a short description of this parameter
                                      description: 'TPP Username for VenafiCodesignAction',
                                      verify_block: proc do |value|
                                        unless value && !value.empty?
                                          UI.user_error!("No TPP UserName for VenafiCodesignAction given, pass using `username: 'username'`")
                                        end
                                        # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                      end),
          FastlaneCore::ConfigItem.new(key: :tpp_password,
                                      # The name of the environment variable
                                      env_name: 'FL_TPP_PASSWORD',
                                      # a short description of this parameter
                                      description: 'TPP Password for VenafiCodesignAction',
                                      verify_block: proc do |value|
                                        unless value && !value.empty?
                                          UI.user_error!("No TPP Password for VenafiCodesignAction given, pass using `password: 'password'`")
                                        end
                                        # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                      end)
        ]
      end

      def self.output
        [
          ['VENAFI_CODESIGN_CUSTOM_VALUE', 'A description of what this value contains']
        ]
      end

      def self.return_value
      end

      def self.authors
        ['zosocanuck']
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
