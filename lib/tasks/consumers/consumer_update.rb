require_relative '../../../config/environment'
require 'bunny'
require 'json'

Rails.logger.info "Iniciando consumidor para actualizar facturas..."
puts "INICIA CONSUMIDOR CONSUMER_UPDATE"

connection = Bunny.new(hostname: 'my-rails-app-rabbitmq-1', user: 'guest', password: 'guest')
connection.start
channel = connection.create_channel
queue = channel.queue('invoice_updates_queue', durable: true)

begin
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    begin
      data = JSON.parse(body)
      order_id = data['order_id']
      invoice_url = data['invoice_url']

      sale_records = Sale.where(order_id: order_id)
      if sale_records.any?
        sale_records.update_all(invoice_url: invoice_url)  # Actualiza todas las filas con el mismo order_id
        Rails.logger.info "Factura actualizada en la base de datos: #{invoice_url}"
      else
        Rails.logger.warn "No se encontró la orden #{order_id} en la base de datos."
      end
    rescue StandardError => e
      Rails.logger.error "Error al actualizar la factura: #{e.message}"
    end
  end

  Rails.logger.info "Esperando nuevos mensajes en invoice_updates_queue..."
  sleep
rescue Interrupt
  Rails.logger.info "Cerrando conexión con RabbitMQ..."
  connection.close
  exit(0)
end
