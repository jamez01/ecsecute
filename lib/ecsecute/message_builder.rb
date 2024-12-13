require 'securerandom'
require 'digest'
require_relative 'utils'

class MessageBuilder
  extend Utils

  ACK_TYPE = 3
  INPUT_TYPE = 1

  def self.build_token_message(token)
    {
      MessageSchemaVersion: "1.0",
      RequestId: SecureRandom.uuid,
      TokenValue: token
    }.to_json
  end

  def self.build_init_message(options, sequence_number)
    payload = {
      cols: options[:cols],
      rows: options[:rows]
    }
    build_agent_message(
      payload.to_json,
      "input_stream_data",
      sequence_number,
      ACK_TYPE,
      1
    )
  end

  def self.build_acknowledge(message_type, sequence_number, message_id)
    payload = {
      AcknowledgedMessageType: message_type,
      AcknowledgedMessageId: message_id,
      AcknowledgedMessageSequenceNumber: sequence_number,
      IsSequentialMessage: true
    }
    build_agent_message(
      payload.to_json,
      "acknowledge",
      0,
      ACK_TYPE,
      0
    )
  end

  def self.build_input_message(text, sequence_number)
    build_agent_message(
      text,
      "input_stream_data",
      sequence_number,
      INPUT_TYPE,
      1
    )
  end

  def self.decode_message(encoded_msg)
    buf = encoded_msg
    payload_length = get_int(buf[116, 4])
    {
      header_length: get_int(buf[0, 4]),
      message_type: get_string(buf[4, 32]).strip,
      schema_version: get_int(buf[36, 4]),
      created_date: get_long(buf[40, 8]),
      sequence_number: get_long(buf[48, 8]),
      flags: get_long(buf[56, 8]),
      message_id: parse_uuid(buf[64, 16]),
      payload_digest: get_string(buf[80, 32]),
      payload_type: get_int(buf[112, 4]),
      payload_length: payload_length,
      payload: buf[120, payload_length].map(&:chr).join
    }
  end

  private

  def self.build_agent_message(payload, message_type, sequence_number, payload_type, flags)
    {
      header_length: 116,
      message_type: message_type,
      schema_version: 1,
      created_date: Time.now.to_i,
      sequence_number: sequence_number,
      flags: flags,
      message_id: SecureRandom.uuid,
      payload_digest: generate_digest(payload),
      payload_type: payload_type,
      payload_length: payload.length,
      payload: payload
    }
  end

  def self.generate_digest(data)
    digest = Digest::SHA256.digest(data)[0, 32]
    digest#.unpack1("H*")
  end

  def self.agent_message_to_buffer(payload)
    buf = Array.new(116 + payload[:payload].length + 4, 0)
    put_int(buf, payload[:header_length], 0)
    put_string(buf, payload[:message_type]+" "*(32-payload[:message_type].size), 4, 32)
    put_int(buf, payload[:schema_version], 36)
    put_long(buf, payload[:created_date], 40)
    put_long(buf, payload[:sequence_number], 48)
    put_long(buf, payload[:flags], 56)
    put_byte_array(buf, payload[:message_id].split('-').join.hex.digits(16).reverse, 64)
    put_string(buf, payload[:payload_digest], 80, 32)
    put_int(buf, payload[:payload_type], 112)
    put_int(buf, payload[:payload_length], 116)
    if payload[:payload].is_a?(String)
      put_string(buf, payload[:payload], 120)
    else
      put_byte_array(buf, payload[:payload], 120)
    end
    buf
  end
end