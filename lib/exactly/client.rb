module Exactly
  class Client
    def initialize(username, password)
      client.wsse.credentials username, password
    end

    def client
      @client ||= ::Savon::Client.new("https://webservice.s6.exacttarget.com/etframework.wsdl")
    end

    def upsert_data_extension(customer_key, properties)
      client.request "UpdateRequest", :xmlns => "http://exacttarget.com/wsdl/partnerAPI" do
        http.headers['SOAPAction'] = 'Update'
        soap.body = {
          "Options" => {
            "SaveOptions" => [
              "SaveOption" => {
                "PropertyName" => "*",
                "SaveAction" => "UpdateAdd"
              }
            ]
          },
          "Objects" => {
            "CustomerKey" => customer_key,
            "Properties" => {
              "Property" => properties.map do
                |k, v| { "Name" => k, "Value" => v }
              end
            }
          },
          :attributes! => { "Objects" => { "xsi:type" => "DataExtensionObject" }}
        }
      end
    end
  end
end
