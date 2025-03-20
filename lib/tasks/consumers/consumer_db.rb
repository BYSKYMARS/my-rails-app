require_relative '../../../config/environment'
require 'bunny'
require 'json'

Rails.logger.info "Iniciando consumidor de órdenes de venta..."
puts "INICIA CONSUMIDOR CONSUMER_DB"

connection = Bunny.new(hostname: 'my-rails-app_rabbitmq_1', user: 'guest', password: 'guest')
connection.start
channel = connection.create_channel
queue_sales = channel.queue('sales_queue', durable: true)

begin
  queue_sales.subscribe(block: true) do |_delivery_info, _properties, body|
    begin
      data = JSON.parse(body)
      order_id = data['order_id']
      email = data['email']
      date_time = data['date_time']
      invoice_url = data['invoice_url']

      data['items'].each do |item|
        Sale.create!(
          order_id: order_id,
          email: email,
          product_cod: item['product_cod'],
          product_name: item['product_name'],
          price: item['price'],
          quantity: item['quantity'],
          total: item['total'],
          date_time: date_time,
          invoice_url: invoice_url
        )
      end
    
    puts "Mensaje recibido: #{body}"

    puts ""
    puts ""
    puts "Inicia Consumidor Consumer_DB"
      Rails.logger.info "Orden de venta guardada en la base de datos con factura: #{invoice_url}"
    rescue StandardError => e
      Rails.logger.error "Error procesando orden de venta: #{e.message}"
    end
  end

  Rails.logger.info "Esperando nuevos mensajes en sales_queue..."
  sleep
rescue Interrupt
  Rails.logger.info "Cerrando conexión con RabbitMQ..."
  connection.close
  exit(0)
end
