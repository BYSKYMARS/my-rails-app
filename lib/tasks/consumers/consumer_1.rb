require 'bunny'
require 'json'

connection = Bunny.new(hostname: 'my-rails-app-rabbitmq-1', user: 'guest', password: 'guest')
connection.start

channel = connection.create_channel
queue = channel.queue('payments_queue', durable: true)

puts " [*] Esperando mensajes para procesar pagos. Para salir, presiona CTRL+C"

queue.subscribe(block: true) do |_delivery_info, _properties, body|
  data = JSON.parse(body)
  puts " [x] Procesando pago del usuario: #{data['email']} por un total de $#{data['total']}"

  # Simulación de procesamiento de pago
  sleep 2
  puts " [✓] Pago procesado correctamente para #{data['email']}"
end
connection.close