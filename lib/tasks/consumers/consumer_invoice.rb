require 'bunny'
require 'json'
require 'stripe'

Stripe.api_key = 'sk_test_51QoFs9P4wrgM4HArCSAbzuPKVaTyMx7cTjB2XoQX08Zkd3uxo8nErZAK4TxvR54rsTMgpEcyO0YxmvbdxC781fR000Ws5ZL9JA'  # Usa variables de entorno en producción

# Configurar conexión con RabbitMQ
connection = Bunny.new(hostname: 'my-rails-app-rabbitmq-1', user: 'guest', password: 'guest')
connection.start
channel = connection.create_channel
queue = channel.queue('invoice_queue', durable: true)
sales_queue = channel.queue('sales_queue', durable: true)  # Cola para consumer_db

puts " [*] Esperando mensajes para generar facturas en Stripe..."

queue.subscribe(block: true) do |_delivery_info, _properties, body|
  data = JSON.parse(body)

  begin
    # 1️⃣ Buscar o crear cliente en Stripe
    customer = Stripe::Customer.list(email: data['email']).data.first
    if customer.nil?
      customer = Stripe::Customer.create(
        email: data['email'],
        name: data['email']
      )
    end

    # 2️⃣ Verificar si el cliente tiene un método de pago
    payment_methods = Stripe::PaymentMethod.list(customer: customer.id, type: 'card').data
    if payment_methods.empty?
      puts " [!] El cliente #{data['email']} no tiene un método de pago. Creando uno automáticamente..."

      # Crear un método de pago usando un token de prueba
      payment_method = Stripe::PaymentMethod.create(
        type: 'card',
        card: {
          token: 'tok_visa'  # ✅ Token de prueba de Stripe
        }
      )

      # Asociar el método de pago al cliente
      Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id)

      # Configurar el método de pago como predeterminado
      Stripe::Customer.update(customer.id, invoice_settings: { default_payment_method: payment_method.id })

      puts " [✓] Método de pago creado con el token de prueba."
      default_payment_method = payment_method.id
    else
      default_payment_method = payment_methods.first.id
    end

    # 3️⃣ Buscar una factura existente sin pagar
    invoices = Stripe::Invoice.list(customer: customer.id, status: 'draft')
    invoice = invoices.data.first

    if invoice.nil?
      invoice = Stripe::Invoice.create(
        customer: customer.id,
        collection_method: 'charge_automatically',
        auto_advance: true,
        metadata: { from: "Tienda Online" }
      )
    end

    # 4️⃣ Asociar el método de pago a la factura (CORRECTA UBICACIÓN)
    Stripe::Invoice.update(invoice.id, default_payment_method: default_payment_method)

    # 5️⃣ Agregar los productos a la factura
    data['items'].each do |item|
      total_amount = (item['price'].to_f * item['quantity'].to_i * 100).to_i  # Convertir a centavos
      Stripe::InvoiceItem.create(
        customer: customer.id,
        invoice: invoice.id,
        amount: total_amount,
        currency: 'usd',
        description: "#{item['product_cod']} - #{item['product_name']} x#{item['quantity']}"
      )
    end

    # 6️⃣ Finalizar y pagar la factura si no está pagada
    invoice.finalize_invoice
    invoice.pay
    invoice_url = invoice.hosted_invoice_url
    puts " [✓] Factura generada y cobrada: #{invoice_url}"
    
    # 7️⃣ Publicar mensaje con la URL de la factura en `sales_queue`
    new_data = data.merge({ "invoice_url" => invoice_url })
    sales_queue.publish(new_data.to_json, persistent: true)
    
    puts " [*] Mensaje enviado a sales_queue con la URL de la factura."
    puts ""
    puts " [*] Esperando mensajes para generar facturas en Stripe..."

  rescue => e
    puts " [✗] Error al procesar la factura: #{e.message}"
  end
end
