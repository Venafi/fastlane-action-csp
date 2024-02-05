module Fastlane
  module Actions
    module SharedValues
      VENAFI_CODESIGN_CUSTOM_VALUE = :VENAFI_CODESIGN_CUSTOM_VALUE
    end

    class VenafiCodesignCertAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:

        vaultID = get_vault_id(params[:tpp_url], params[:tpp_access_token], "\\VED\\Policy\\" + params[:tpp_policydn] + "\\" + params[:tpp_project] + " " + params[:tpp_environment] + " Certificate")
        cert = upload_csr(params[:tpp_url], params[:tpp_access_token], vaultID, params[:certificate_type])
        import_cert(params[:apple_id], params[:tpp_url], params[:tpp_access_token], params[:tpp_policydn], params[:tpp_project], params[:tpp_environment], cert)

      end

      def self.import_cert(apple_id, url, access_token, policy_dn, project, environment, cert)
        #
        # Import code signing cert
        # Token scope:  Certificate:Discover
        #
        url = URI(url + "/vedsdk/certificates/import")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Post.new(url)
        request["Authorization"] = "Bearer " + access_token
        request["Content-Type"] = "application/json"
        request.body = JSON.dump({
          "PolicyDN": "\\VED\\Policy\\" + policy_dn,
          "ObjectName": project + " " + environment + " Certificate",
          "CertificateData": cert
        })

        begin
          response = https.request(request)
          #puts JSON.parse(response.read_body)
        rescue StandardError
          UI.error "error: " + response.code + " - " + response.read_body
        end
      end

      def self.upload_csr(url, access_token, vault_id, certificate_type)
        # Get CSR from Venafi CodeSign Protect and upload to Apple
        # Token scope:  Restricted:Manage
        #
        url = URI(url + "/vedsdk/secretstore/retrieve")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Post.new(url)
        request["Authorization"] = "Bearer " + access_token
        request["Content-Type"] = "application/json"
        request.body = JSON.dump({
          "VaultID": vault_id
        })

        begin
          response = https.request(request)
          parsed = JSON.parse(response.read_body)
          venafi_csr = "-----BEGIN CERTIFICATE REQUEST-----\n" + parsed['Base64Data'] + "\n-----END CERTIFICATE REQUEST-----"
        rescue StandardError
          UI.error "error: " + response.code + " - " + response.read_body
        end

        Spaceship::Portal.login(apple_id)

        # See spaceship certificate types: https://github.com/fastlane/fastlane/blob/master/spaceship/lib/spaceship/portal/certificate.rb
        case certificate_type
        when "PRODUCTION" # iOS Distribution
          cert = Spaceship.certificate.Production.create!(csr: venafi_csr)
        when "IOSDEVELOPMENT" # iOS Development
          cert = Spaceship.certificate.Development.create!(csr: venafi_csr)
        when "APPLEDEVELOPMENT" # Development
          cert = Spaceship.certificate.AppleDevelopment.create!(csr: venafi_csr)
        when "APPLEDISTRIBUTION" # Distribution
          cert = Spaceship.certificate.AppleDistribution.create!(csr: venafi_csr)
        when "MACAPPDISTRIBUTION" # Mac App Distribution
          cert = Spaceship.certificate.MacAppDistribution.create!(csr: venafi_csr)
        when "MACDEVELOPMENT" # Mac Development
          cert = Spaceship.certificate.MacDevelopment.create!(csr: venafi_csr)
        when "MACINSTALLERDISTRIBUTION" # Mac Installer Disribution
          cert = Spaceship.certificate.MacInstallerDistribution.create!(csr: venafi_csr)
        when "DEVELOPERIDAPPLICATION" # Developer ID Application
          cert = Spaceship.certificate.DeveloperIdApplication.create!(csr: venafi_csr)
        when "DEVELOPERIDINSTALLER" # Developer ID Installer
          cert = Spaceship.certificate.DeveloperIdInstaller.create!(csr: venafi_csr)
        else
          UI.error "invalid certificate type"
        end

        #puts cert.download

        #prod_certs = Spaceship.certificate.production.all
        #return prod_certs[1].download
        return cert.download
      end

      def self.get_vault_id(url, access_token, cert_dn)
        # Get VaultID
        # Token scope:  Configuration
        #
        url = URI(url + "/vedsdk/config/read")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Post.new(url)
        request["Authorization"] = "Bearer " + access_token
        request["Content-Type"] = "application/json"
        request.body = JSON.dump({
          "ObjectDN": cert_dn,
          "AttributeName": "CSR Vault ID",
        })

        begin
          response = https.request(request)
          parsed = JSON.parse(response.read_body)
          if parsed['Values'].size == 0
            UI.error "invalid CodeSign Protect certificate"
          else
            return parsed['Values'][0]
          end
        rescue StandardError
          UI.error "error: " + response.code + " - " + response.read_body
        end

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
          FastlaneCore::ConfigItem.new(key: :tpp_access_token,
                                      # The name of the environment variable
                                      env_name: 'FL_TPP_ACCESS_TOKEN',
                                      # a short description of this parameter
                                      description: 'TPP access token for VenafiCodesignCertAction',
                                      verify_block: proc do |value|
                                        unless value && !value.empty?
                                          UI.user_error!("No TPP access token for VenafiCodesignCertAction given, pass using `access_token: 'xxxxx'`")
                                        end
                                        # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                      end),
          FastlaneCore::ConfigItem.new(key: :tpp_policydn,
                                      # The name of the environment variable
                                      env_name: 'FL_TPP_POLICYDN',
                                      # a short description of this parameter
                                      description: 'TPP Policy DN for VenafiCodesignCertAction',
                                      verify_block: proc do |value|
                                        unless value && !value.empty?
                                          UI.user_error!("No TPP Policy DN for VenafiCodesignCertAction given, pass using `policydn: 'Code Signing\\Certificates'`")
                                        end
                                        # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                      end),
          FastlaneCore::ConfigItem.new(key: :tpp_project,
                                      # The name of the environment variable
                                      env_name: 'FL_TPP_PROJECT',
                                      # a short description of this parameter
                                      description: 'CSP Project for VenafiCodesignCertAction',
                                      verify_block: proc do |value|
                                        unless value && !value.empty?
                                          UI.user_error!("No Project for VenafiCodesignCertAction given, pass using `project: 'MyProject'`")
                                        end
                                        # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                      end),
          FastlaneCore::ConfigItem.new(key: :tpp_environment,
                                      # The name of the environment variable
                                      env_name: 'FL_TPP_ENVIRONMENT',
                                      # a short description of this parameter
                                      description: 'CSP environment for VenafiCodesignCertAction',
                                      verify_block: proc do |value|
                                        unless value && !value.empty?
                                          UI.user_error!("No CSP environment for VenafiCodesignCertAction given, pass using `environment: 'MySigner'`")
                                        end
                                        # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                      end),
            FastlaneCore::ConfigItem.new(key: :certificate_type,
                                      # The name of the environment variable
                                      env_name: 'FL_CERTIFICATE_TYPE',
                                      # a short description of this parameter
                                      description: 'Apple Certificate Type (i.e. Production, Development, etc.)',
                                      verify_block: proc do |value|
                                        unless value && !value.empty?
                                          UI.user_error!("No Apple certificate type given, pass using `certificate_type: 'Production'`")
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

      def self.example_code
        [
          'venafi_codesign_cert(
            tpp_url: "https://tpp.example.com",
            tpp_access_token: "lfhTMYQtLK+oHS6cUvOCLh==",
            tpp_policydn: "Code Signing\\Certificates",
            tpp_project: "AppleSigning",
            tpp_environment: "MyApp",
            certificate_type: "PRODUCTION"
          )'
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
