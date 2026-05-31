module Fastlane
  module Actions
    module SharedValues
      VENAFI_CODESIGN_CUSTOM_VALUE = :VENAFI_CODESIGN_CUSTOM_VALUE
    end

    class VenafiCodesignAuthAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        sh("tkdriverconfig", "getgrant", "--force", "--authurl=#{params[:tpp_url]}/vedauth", "--hsmurl=#{params[:tpp_url]}/vedhsm", "--username=#{params[:tpp_username]}", "--password=#{params[:tpp_password]}", log: false)
        sh("tkdriverconfig", "sync", log: false)
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

                                         # Validate URL to prevent SSRF/credential exfiltration (CWE-918)
                                         begin
                                           uri = URI.parse(value)
                                           unless uri.scheme == 'https'
                                             UI.user_error!("TPP URL must use HTTPS scheme for security, got: #{uri.scheme}")
                                           end
                                           unless uri.host
                                             UI.user_error!("TPP URL must have a valid hostname")
                                           end

                                           # Optional allowlist check via FL_TPP_URL_ALLOWLIST (comma-separated domain patterns)
                                           allowlist = ENV['FL_TPP_URL_ALLOWLIST']
                                           if allowlist && !allowlist.empty?
                                             patterns = allowlist.split(',').map(&:strip)
                                             unless patterns.any? { |pattern| uri.host.end_with?(pattern) || uri.host == pattern }
                                               UI.user_error!("TPP URL host '#{uri.host}' does not match allowlist: #{patterns.join(', ')}")
                                             end
                                           end
                                         rescue URI::InvalidURIError => e
                                           UI.user_error!("Invalid TPP URL format: #{e.message}")
                                         end
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
