require 'faye/websocket'
require 'logger'
require 'securerandom'
require 'digest'
require 'readline'
require_relative 'web_socket_handler'
require_relative 'message_builder'
require_relative 'utils'

class SSM
  def initialize(region: 'us-east-1', interactive: true, token:, stream_url:)
    @log = Logger.new("./ssm.log")
    @message_sequence_number = 1
    @region = region
    @interactive = true
    @token = token
    @stream_url = stream_url
    @token_msg = MessageBuilder.build_token_message(token)
    @web_socket_handler = WebSocketHandler.new(@stream_url, @token_msg, @interactive, @log, self)
    @web_socket_handler.open_socket
  end

  def handle_message(connection,msg)
  end

  def send_init_message(connection, term_options)
    response = MessageBuilder.build_init_message(term_options, @message_sequence_number)
    @log.debug("Sending init message: #{response}")
    connection.send(response)
  end

  def build_acknowledge(message_type, sequence_number, message_id)
    ack_message = MessageBuilder.build_acknowledge(message_type, sequence_number, message_id)
    @log.debug("Sending ack message: #{ack_message}")
    @message_sequence_number += 1
    @web_socket_handler.send_message(ack_message)
  end

  def build_input_message(text, sequence_number)
    input_message = MessageBuilder.build_input_message(text, sequence_number)
    @log.debug("Sending input message: #{input_message}")
    @message_sequence_number += 1
    @web_socket_handler.send_msg(input_message)
  end
end