require 'websocket-client-simple'
require 'securerandom'
require 'digest'

class SSM
  ACK_TYPE = 3
  INPUT_TYPE = 1

  def initialize(region: 'us-east-1', interactive: true, token:, stream_url:)
    @message_sequence_number = 0
    @region = region
    @interactive = interactive
    @token = token
    @stream_url = stream_url
    open_socket
  end

  def handle_message(msg)
    decoded_msg = decode_message(msg.data)
    # Process the decoded message
  end

  def open_socket
    ws = WebSocket::Client::Simple.connect(@stream_url)

    ws.on :open do
      puts "Connected to the stream"
      @ws.send(build_token_message)
    end

    ws.on :message do |msg|
      handle_message(msg)
    end

    ws.on :close do |e|
      puts "Connection closed: #{e}"
    end

    ws.on :error do |e|
      puts "Error: #{e}"
    end

    loop do
      input = $stdin.gets
      ws.send(build_input_message(input, @message_sequence_number += 1)) 
    end
  end

  def send_init_message(connection, term_options)
    connection.send(build_init_message(term_options))
  end

  def build_token_message
    {
      MessageSchemaVersion: "1.0",
      RequestId: SecureRandom.uuid,
      TokenValue: @token
    }.to_json
  end

  def build_init_message(options)
    payload = {
      cols: options[:cols],
      rows: options[:rows]
    }
    init_message = build_agent_message(
      payload.to_json,
      "input_stream_data",
      @message_sequence_number,
      ACK_TYPE,
      1
    )
    agent_message_to_buffer(init_message)
  end

  def build_acknowledge(message_type, sequence_number, message_id)
    payload = {
      AcknowledgedMessageType: "output_stream_data",
      AcknowledgedMessageId: message_id,
      AcknowledgedMessageSequenceNumber: sequence_number,
      IsSequentialMessage: true
    }
    ack_message = build_agent_message(
      payload.to_json,
      "acknowledge",
      sequence_number,
      ACK_TYPE,
      0
    )
    agent_message_to_buffer(ack_message)
  end

  def build_input_message(text, sequence_number)
    input_message = build_agent_message(
      text,
      "input_stream_data",
      sequence_number,
      INPUT_TYPE,
      sequence_number == 1 ? 0 : 1
    )
    agent_message_to_buffer(input_message)
  end

  def decode_message(encoded_msg)
    buf = Base64.decode64(encoded_msg).unpack('C*')
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
      payload_length: get_int(buf[116, 4]),
      payload: buf[120, buf.length - 120]
    }
  end

  private

  def build_agent_message(payload, message_type, sequence_number, payload_type, flags)
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

  def generate_digest(data)
    Digest::SHA256.hexdigest(data)[0, 32]
  end

  def agent_message_to_buffer(payload)
    buf = Array.new(116 + payload[:payload].length + 4, 0)
    put_int(buf, payload[:header_length], 0)
    put_string(buf, payload[:message_type], 4, 32)
    put_int(buf, payload[:schema_version], 36)
    put_long(buf, payload[:created_date], 40)
    put_long(buf, payload[:sequence_number], 48)
    put_long(buf, payload[:flags], 56)
    put_byte_array(buf, payload[:message_id].split('-').join.hex.digits(16).reverse, 64)
    put_string(buf, payload[:payload_digest], 80)
    put_int(buf, payload[:payload_type], 112)
    put_int(buf, payload[:payload_length], 116)
    if payload[:payload].is_a?(String)
      put_string(buf, payload[:payload], 120)
    else
      put_byte_array(buf, payload[:payload], 120)
    end
    buf
  end

  def put_int(buf, data, offset)
    byte_array = int_to_byte_array(data)
    4.times { |i| buf[offset + i] = byte_array[i] }
  end

  def put_long(buf, data, offset)
    byte_array = long_to_byte_array(data)
    8.times { |i| buf[offset + i] = byte_array[i] }
  end

  def put_string(buf, data, offset, max_length = nil)
    if max_length
      diff = max_length - data.length
      diff.times { |i| buf[offset + i] = 0 }
      max_length.times { |i| buf[offset + i + diff] = data[i - diff] ? data[i - diff].ord : 0 }
    else
      data.length.times { |i| buf[offset + i] = data[i] ? data[i].ord : 0 }
    end
  end

  def put_byte_array(buf, data, offset)
    data.length.times { |i| buf[offset + i] = data[i] }
  end

  def long_to_byte_array(long)
    byte_array = Array.new(8, 0)
    8.times do |index|
      byte = long & 0xff
      byte_array[7 - index] = byte
      long = (long - byte) / 256
    end
    byte_array
  end

  def int_to_byte_array(int)
    byte_array = Array.new(4, 0)
    4.times do |index|
      byte = int & 0xff
      byte_array[3 - index] = byte
      int = (int - byte) / 256
    end
    byte_array
  end

  def get_int(buf)
    data = 0
    4.times { |i| data += buf[i] << ((3 - i) * 8) }
    data
  end

  def get_string(buf)
    buf.map { |b| b.chr }.join
  end

  def get_long(buf)
    data = 0
    buf.length.times { |i| data += buf[buf.length - 1 - i] * (256**i) }
    data
  end

  def parse_uuid(buf)
    part1 = buf[8..11].map { |b| format_num(b.to_s(16)) }.join
    part2 = buf[12..13].map { |b| format_num(b.to_s(16)) }.join
    part3 = buf[14..15].map { |b| format_num(b.to_s(16)) }.join
    part4 = buf[0..1].map { |b| format_num(b.to_s(16)) }.join
    part5 = buf[2..7].map { |b| format_num(b.to_s(16)) }.join
    "#{part1}-#{part2}-#{part3}-#{part4}-#{part5}"
  end

  def format_num(num)
    num.rjust(2, '0')
  end
end