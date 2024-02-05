[![Venafi](https://raw.githubusercontent.com/Venafi/.github/master/images/Venafi_logo.png)](https://www.venafi.com/)
[![Apache 2.0 License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Community Supported](https://img.shields.io/badge/Support%20Level-Community-brightgreen)
![Compatible with TPP 23.x](https://img.shields.io/badge/Compatibility-TPP%2023.x-f9a90c)

### Automate Apple Code Signing with Venafi CodeSign Protect and Fastlane

Make sure to have the latest Venafi CodeSign Protect client for MacOS installed and configured. See [documentation](https://docs.venafi.com/Docs/current/TopNav/Content/CodeSigning/t-codesigning-setting-up-keychain.php?tocpath=CodeSign%20Protect%7CSetting%20up%20the%20CodeSign%20Protect%20clients%7CSetting%20up%20macOS%20Keychain%20clients%7C_____0)

The `venafi_codesign_auth` action will automate authentication/authorization for the CodeSign Protect client.

The `venafi_codesign_cert` action will automate the issuance of Apple code signing certificates within Venafi CodeSign Protect.  This automation leverages API access and therefore you will need an appropriate `API Integration` with the following minimum scopes:

`restricted:manage;configuration;certificate:discover`

To fetch an appropriate `access_token`, you can use the following API call:

```
POST /vedauth/authorize/oauth HTTP/1.1
Host: tpp.example.com
Content-Type: application/json
Content-Length: 147

{
   "client_id":"apple-cert",
   "password":"SuperSecretPassword!",
   "scope":"restricted:manage;configuration;certificate:discover",
   "username":"local:myaccount"
}
```

Or using `curl`:

```
curl --location 'https://tpp.example.com/vedauth/authorize/oauth' \
--header 'Content-Type: application/json' \
--data '{
   "client_id":"apple-cert",
   "password":"SuperSecretPassword!!",
   "scope":"restricted:manage;configuration;certificate:discover",
   "username":"local:myaccount"
}'
```

### Issue Apple Code Signing Certificate

Here is an example lane:

```
 lane :venafi_cert do
    app_store_connect_api_key(
      key_id: "<insert key id>",
      issuer_id: "<insert issuer id>",
      key_filepath: "/Users/developer/private_keys/AuthKey_ABC123.p8",
      duration: 1200
    )
    venafi_codesign_cert(
      tpp_url: "https://tpp.example.com",
      tpp_access_token: "lfhTMYQtLK+oHS6cUvOCLh==",
      tpp_policydn: "Code Signing\\Certificates",
      tpp_project: "AppleTestProject",
      tpp_environment: "Development",
      certificate_type: "APPLEDEVELOPMENT"
    )
```

### Sign with CodeSign Protect:

```
venafi_codesign_auth(tpp_url: "https://tpp.example.com",
                    tpp_username: "sample-cs-user",
                    tpp_password: "MySecret!"
                    )
    build_app(
      project: "SampleIOSApp.xcodeproj",
      scheme: "SampleIOSApp",
      output_name: "SampleIOSApp.ipa",
      export_method: "development",
      export_options: {
         provisioningProfiles: {
         "com.example.SampleIOSApp" => "Venafi Profile"
         }
      }
    )
```