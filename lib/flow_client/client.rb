# frozen_string_literal: true

require "flow/access/access_services_pb"
require "flow/execution/execution_services_pb"
require "json"

# Collection of classes to interact with the Flow blockchain
module FlowClient
  # Flow client
  class Client
    attr_accessor :address_aliases

    def initialize(node_address)
      @stub = Access::AccessAPI::Stub.new(node_address, :this_channel_is_insecure)
      @address_aliases = {}
    end

    def ping
      req = Access::PingRequest.new
      @stub.ping(req)
    end

    # Accounts
    def get_account(address)
      req = Access::GetAccountAtLatestBlockRequest.new(address: to_bytes(address))
      res = @stub.get_account_at_latest_block(req)
      res.account
    end

    # Scripts
    def execute_script(script, args = [])
      req = Access::ExecuteScriptAtLatestBlockRequest.new(
        script: FlowClient::Utils.substitute_address_aliases(script, @address_aliases),
        arguments: args
      )
      res = @stub.execute_script_at_latest_block(req)
      parse_json(res.value)
    end

    # Blocks
    def get_latest_block(is_sealed: true)
      req = Access::GetLatestBlockRequest.new(
        is_sealed: is_sealed
      )

      @stub.get_latest_block(req)
    end

    # Events
    def get_events(type, start_height, end_height)
      req = Access::GetEventsForHeightRangeRequest.new(
        type: type,
        start_height: start_height,
        end_height: end_height
      )
      @stub.get_events_for_height_range(req)
    end

    # Transactions

    # Send a FlowClient::Transaction transaction to the blockchain
    def send_transaction(transaction)
      transaction.address_aliases = @address_aliases
      req = Access::SendTransactionRequest.new(
        transaction: transaction.to_protobuf_message
      )
      @stub.send_transaction(req)
    end

    def get_transaction(transaction_id)
      req = Access::GetTransactionRequest.new(
        id: to_bytes(transaction_id)
      )
      @stub.get_transaction(req)
    end

    def get_transaction_result(transaction_id)
      req = Access::GetTransactionRequest.new(
        id: to_bytes(transaction_id)
      )
      @stub.get_transaction_result(req)
    end

    private

    def parse_json(event_payload)
      JSON.parse(event_payload, object_class: OpenStruct)
    end

    def to_bytes(string)
      [string].pack("H*")
    end

    def to_string(bytes)
      bytes.unpack1("H*")
    end
  end
end
