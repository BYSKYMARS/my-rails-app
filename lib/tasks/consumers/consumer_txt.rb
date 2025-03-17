require 'bunny'
require 'json'

connection = Bunny.new(hostname: 'my-rails-app-rabbitmq-1', user: 'guest', password: 'guest')
connection.start

channel = connection.create_channel
queue_txt = channel.queue('payments_txt_queue', durable: true)
queue_excel = channel.queue('payments_excel_queue', durable: true)  # Nueva cola

puts " [*] Esperando mensajes para generar recibos en TXT..."

queue_txt.subscribe(block: true) do |_delivery_info, _properties, body|
  data = JSON.parse(body)
  filename = "#{data['email']}_#{Time.now.strftime('%Y-%m-%d')}.txt"
  
  File.open(filename, 'a') do |file|
    file.puts "Usuario: #{data['email']}"
    file.puts "Total: $#{data['total']}"
    file.puts "Fecha: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    file.puts "Productos:"
    data['items'].each do |item|
      file.puts "- Producto ID: #{item['product_id']}, Cantidad: #{item['quantity']}"
    end
    file.puts "---------------------------------------"
  end

  puts " [✓] Recibo guardado en #{filename}"

  # **Enviar confirmación a payments_excel_queue**
  message = data.to_json
  queue_excel.publish(message, persistent: true)
  puts " [→] Mensaje enviado a payments_excel_queue para actualizar Excel."
end
