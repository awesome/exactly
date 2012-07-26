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

    def delete_from_data_extension(customer_key, properties)
      client.request "DeleteRequest", :xmlns => "http://exacttarget.com/wsdl/partnerAPI" do
        http.headers['SOAPAction'] = 'Delete'
        soap.body = {
          "DeleteOptions" => {},
          "Objects" => {
            "CustomerKey" => customer_key,
            "Keys" => {
              "Key" => properties.map do
                |k, v| { "Name" => k, "Value" => v }
              end
            }
          },
          :attributes! => { "Objects" => { "xsi:type" => "DataExtensionObject" }}
        }
      end
    end

    def triggered_send(customer_key, attributes)
      attributes_without_email = attributes.reject{|k,v| k == :email}
      client.request "CreateRequest", :xmlns => "http://exacttarget.com/wsdl/partnerAPI" do
        http.headers['SOAPAction'] = 'Create'
        soap.body = {
          "Objects" => {
            "TriggeredSendDefinition" => {
              "CustomerKey" => customer_key
            },
            "Subscribers" => {
              "EmailAddress"  => attributes[:email],
              "SubscriberKey" => attributes[:email],
              "Attributes"    => attributes_without_email.map do
                |k, v| { "Name" => k, "Value" => v }
              end
            }
          },
          :attributes! => { "Objects" => { "xsi:type" => "TriggeredSend" }}
        }
      end
    end
  end
end
