require 'faye/websocket'
require 'eventmachine'

class WebSocketHandler
  def initialize(stream_url, token_msg, interactive, log, ssm)
    @stream_url = stream_url
    @token_msg = token_msg
    @interactive = interactive
    @log = log
    @ssm = ssm
  end

  def send_msg(msg)
    # @log.debug("Sending message: #{msg}")
    # @log.debug("Sending message to buffer: #{MessageBuilder.agent_message_to_buffer(msg)}")
    # @log.debug("Message decoded: #{MessageBuilder.decode_message(MessageBuilder.agent_message_to_buffer(msg))}")
    @ws.send(MessageBuilder.agent_message_to_buffer(msg))
  end

  def open_socket
    EM.run do
      @ws = Faye::WebSocket::Client.new(@stream_url)

      @ws.on :open do |event|
        puts "Connected to the stream"
        @ws.send(@token_msg)
      end

      @ws.on :message do |event|
        decoded_msg = MessageBuilder.decode_message(event.data)
        if decoded_msg[:message_type] == "output_stream_data" && decoded_msg[:payload_type] == 1
          print decoded_msg[:payload]
          ack = MessageBuilder.build_acknowledge(decoded_msg[:message_type], decoded_msg[:sequence_number], decoded_msg[:message_id])
          @log.debug("ACK: #{ack.inspect}")
          send_msg(ack)
        elsif decoded_msg[:message_type] == "acknowledge"
          @log.debug("Received ack message: #{decoded_msg}")
        else
          @log.debug("Received unknown message: #{decoded_msg}")
        end    
      end

      @ws.on :close do |event|
        puts "Connection closed: #{event.code}, #{event.reason}"
        EM.stop
      end

      @ws.on :error do |event|
        puts "Error: #{event.message}"
      end

      if @interactive
        EM.add_periodic_timer(0.25) do
          @input_buffer ||= ""
          if @ws.ready_state == Faye::WebSocket::API::OPEN
            ch = STDIN.read_nonblock(255) rescue nil
            #@input_buffer << ch unless ch.nil? || ch.empty? || ch == "\n"
            @ssm.build_input_message(ch, @ssm.instance_variable_get(:@message_sequence_number)) unless ch.nil? || ch.empty?
              # @ssm.instance_variable_set(:@message_sequence_number, @ss
          else
            puts "Connection not ready"
          end
        end
      end
    end
  end

  def send_message(message)
    @ws.send(message)
  end
end