require 'bunny'
require 'json'

connection = Bunny.new(hostname: 'my-rails-app-rabbitmq-1', user: 'guest', password: 'guest')
connection.start

channel = connection.create_channel
queue = channel.queue('payments_queue', durable: true)

puts " [*] Esperando mensajes para enviar confirmaciones por email..."

queue.subscribe(block: true) do |_delivery_info, _properties, body|
  data = JSON.parse(body)
  puts " [x] Enviando email de confirmación a #{data['email']}..."

  # Simulación de envío de email
  sleep 1
  puts " [✓] Email enviado a #{data['email']}"
end
connection.close