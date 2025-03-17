class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def new
    @cart = current_user.cart
    @total = calcular_total(@cart)
  end

  def create
    @cart = current_user.cart
    @total = calcular_total(@cart)

    Rails.logger.info "Total del pago: #{@total}"

    if @total <= 0
      flash[:error] = "El total del pago debe ser mayor que 0."
      return redirect_to cart_path
    end

    Rails.logger.info "Stripe Token recibido: #{params[:stripeToken]}"

    Stripe.api_key = ENV["STRIPE_SECRET_KEY"] || 'sk_test_51QoFs9P4wrgM4HArCSAbzuPKVaTyMx7cTjB2XoQX08Zkd3uxo8nErZAK4TxvR54rsTMgpEcyO0YxmvbdxC781fR000Ws5ZL9JA'

    charge = Stripe::Charge.create(
      amount: (@total * 100).to_i,
      currency: 'usd',
      source: params[:stripeToken],
      description: "Pago de #{current_user.email}"
    )

    actualizar_stock(@cart)

    # **Publicar en RabbitMQ (payments_invoice_queue,sales queue)**
    # checkout
    publicar_en_rabbitmq(@cart, @total)

    @cart.line_items.destroy_all

    redirect_to root_path, notice: 'Pago procesado exitosamente.'
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to new_payment_path
  end

  private

  def calcular_total(cart)
    cart.line_items.sum { |item| item.product.precio * item.quantity }
  end

  def actualizar_stock(cart)
    cart.line_items.each do |line_item|
      product = line_item.product
      product.update(stock: product.stock - line_item.quantity)
    end
  end

  # def checkout
  #   publicar_en_rabbitmq(@cart, @total)   # ✅ Publicar en la cola de boletas
  #   publicar_orden_de_venta(@cart, @total) # ✅ Publicar en la cola de ventas
  # end
  

  def publicar_en_rabbitmq(cart, total)
    begin
      Rails.logger.info "Iniciando conexión con RabbitMQ..."
      connection = Bunny.new(hostname: 'my-rails-app-rabbitmq-1', user: 'guest', password: 'guest')
      connection.start

      channel = connection.create_channel
      queue_invoice = channel.queue('invoice_queue', durable: true)

      order_id = SecureRandom.random_number(10_000) # ID aleatorio para la orden

      message = {
        from: "La Tiendita de Don Pepe",
        order_id: order_id, 
        user_id: current_user.id,
        email: current_user.email,
        total: total,
        date_time: Time.now.iso8601,
        items: cart.line_items.map do |item|
          {
            product_cod: item.product.codigo,
            product_id: item.product.id,
            product_name: item.product.nombre,
            quantity: item.quantity,
            price: item.product.precio,
            total: item.product.precio * item.quantity
          }
        end
      }.to_json

      Rails.logger.info "Publicando mensaje en RabbitMQ (Cola invoice): #{message}"
      queue_invoice.publish(message, persistent: true)
      Rails.logger.info "Mensaje enviado correctamente a invoice_queue."

      connection.close
      Rails.logger.info "Conexión con RabbitMQ cerrada."
    rescue StandardError => e
      Rails.logger.error "Error enviando mensaje a RabbitMQ: #{e.message}"
    end
  end

  # def publicar_orden_de_venta(cart, total)
  #   return if cart.line_items.empty?
  
  #   begin
  #     Rails.logger.info "Preparando orden para enviar a RabbitMQ..."
  
  #     order_id = SecureRandom.random_number(10_000) # ID aleatorio para la orden
  
  #     message = {
  #       order_id: order_id,
  #       email: current_user.email,
  #       date_time: Time.now.iso8601,
  #       items: cart.line_items.map do |item|
  #         {
  #           product_cod: item.product.codigo,
  #           product_name: item.product.nombre,
  #           price: item.product.precio,
  #           quantity: item.quantity,
  #           total: item.product.precio * item.quantity
  #         }
  #       end
  #     }.to_json
  
  #     Rails.logger.info "Iniciando conexión con RabbitMQ..."
  #     connection = Bunny.new(hostname: 'my-rails-app-rabbitmq-1', user: 'guest', password: 'guest')
  #     connection.start
  
  #     channel = connection.create_channel
  #     queue_sales = channel.queue('sales_queue', durable: true)
  
  #     Rails.logger.info "Publicando mensaje en RabbitMQ: #{message}"
  #     queue_sales.publish(message, persistent: true)
  
  #     connection.close
  #     Rails.logger.info "Mensaje enviado correctamente."
  
  #   rescue StandardError => e
  #     Rails.logger.error "Error enviando mensaje a RabbitMQ: #{e.message}"
  #   end
  # end
  
end