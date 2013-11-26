module Exactly
  class ExactlyError < RuntimeError
    attr_reader :response
    def initialize(response)
      @response = response
      super(message)
    end
  end

  class SoapFaultError < RuntimeError; end

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
      @username = username
      @password = password
    end

    def client
      @client ||= ::Savon.client(:wsse_auth => [@username,@password]) do
        wsdl "https://webservice.s6.exacttarget.com/etframework.wsdl"
        namespace "http://exacttarget.com/wsdl/partnerAPI"
      end
    end

    def upsert_subscriber(customer_key, email, lists = [])
      response = client.call(
        :create,
        :soap_action => "Create",
        :message => {
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
          :attributes! => {"Objects" =>{ "xsi:type" => "tns:Subscriber" }}
        })
      if response.to_hash[:create_response][:overall_status] != 'OK'
        raise Exactly::UpsertSubscriberFailed.new(response)
      end
    rescue Savon::SOAPFault => ex
      raise Exactly::SoapFaultError, "Error: Could not upsert subscriber #{customer_key}/#{email} to ExactTarget: #{ex.message}"
    end

    def unsubscribe_subscriber(customer_key, email, lists = [])
      response = client.call(
        :create,
        :soap_action => "Create",
        :message => {
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
              { "ID" => list_id, "Status" => "Unsubscribed" }
            }
          },
          :attributes! => {"Objects" =>{ "xsi:type" => "tns:Subscriber" }}
        })
      if response.to_hash[:create_response][:overall_status] != 'OK'
        raise Exactly::UpsertSubscriberFailed.new(response)
      end
    rescue Savon::SOAPFault => ex
      raise Exactly::SoapFaultError, "Error: Could not upsert subscriber #{customer_key}/#{email} to ExactTarget: #{ex.message}"
    end

    def upsert_data_extension(customer_key, properties)
      response = client.call(
        :update,
        :soap_action => "Update",
        :message => {
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
              "Property" => properties.map do |k, v|
                { "Name" => k, "Value" => v }
              end
            }
          },
          :attributes! => { "Objects" => { "xsi:type" => "tns:DataExtensionObject" }}
        })
      if response.to_hash[:update_response][:overall_status] != 'OK'
        raise Exactly::UpsertDataExtensionFailed.new(response)
      end
    end

    def delete_from_data_extension(customer_key, properties)
      response = client.call(
        :delete,
        :soap_action => "Delete",
        :message => {
          "DeleteOptions" => {},
          "Objects" => {
            "CustomerKey" => customer_key,
            "Keys" => {
              "Key" => properties.map do |k, v|
                { "Name" => k, "Value" => v }
              end
            }
          },
          :attributes! => { "Objects" => { "xsi:type" => "tns:DataExtensionObject" }}
        })
      if response.to_hash[:delete_response][:overall_status] != 'OK'
        raise Exactly::TriggeredSendFailed.new(response)
      end
    end

    def triggered_send(customer_key, attributes)
      attributes_without_email = attributes.reject{|k,v| k == :email}
      response = client.call(
        :create,
        :soap_action => "Create",
        :message => {
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
          :attributes! => { "Objects" => { "xsi:type" => "tns:TriggeredSend" }}
        })
      if response.to_hash[:create_response][:overall_status] != 'OK'
        raise Exactly::TriggeredSendFailed.new(response)
      end
    end
  end
end
