module Exactly
  class ExactlyError < StandardError
    attr_reader :response
    def initialize(response)
      @response = response
      super(message)
    end
  end

  class UpsertDataExtensionFailed < ExactlyError
    def message
      @response.to_hash[:update_response][:results][:status_message]
    end
  end

  class CreateError < ExactlyError
    def message
      @response.to_hash[:create_response][:results][:status_message]
    end
  end

  class TriggeredSendFailed < CreateError; end
  class UpsertSubscriberFailed < CreateError; end

  class Client
    def initialize(username, password)
      client.wsse.credentials username, password
    end

    def client
      @client ||= ::Savon::Client.new("https://webservice.s6.exacttarget.com/etframework.wsdl")
    end

    def upsert_subscriber(customer_key, email, lists = [])
      response = client.request "CreateRequest", :xmlns => "http://exacttarget.com/wsdl/partnerAPI" do
        http.headers['SOAPAction'] = 'Create'
        body = {
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
            "EmailAddress" => email,
            "Lists" => Array(lists).map{|list_id|
              { "ID" => list_id, "Status" => "Active" }
            }
          },
          :attributes! => { "Objects" => { "xsi:type" => "Subscriber" }}
        }

        soap.body = body
      end
      if response.to_hash[:create_response][:overall_status] != 'OK'
        raise Exactly::UpsertSubscriberFailed.new(response)
      end
    end

    def upsert_data_extension(customer_key, properties)
      response = client.request "UpdateRequest", :xmlns => "http://exacttarget.com/wsdl/partnerAPI" do
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
      if response.to_hash[:update_response][:overall_status] != 'OK'
        raise Exactly::UpsertDataExtensionFailed.new(response)
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
      response = client.request "CreateRequest", :xmlns => "http://exacttarget.com/wsdl/partnerAPI" do
        http.headers['SOAPAction'] = 'Create'
        soap.body = {
          "Objects" => {
            "TriggeredSendDefinition" => {
              "CustomerKey" => customer_key
            },
            "Subscribers" => {
              "EmailAddress"  => attributes[:email],
              "SubscriberKey" => attributes[:subscriber_key],
              "Attributes"    => attributes_without_email.map do
                |k, v| { "Name" => k, "Value" => v }
              end
            }
          },
          :attributes! => { "Objects" => { "xsi:type" => "TriggeredSend" }}
        }
      end
      if response.to_hash[:create_response][:overall_status] != 'OK'
        raise Exactly::TriggeredSendFailed.new(response)
      end
    end
  end
end
