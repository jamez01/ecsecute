module Utils
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
      data.length.times { |i| buf[offset + i] = data[i] ? data[i].ord : 0 }
      (max_length - data.length).times { |i| buf[offset + data.length + i] = 32 }
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