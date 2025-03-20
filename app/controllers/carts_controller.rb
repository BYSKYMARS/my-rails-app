class CartsController < ApplicationController
    before_action :authenticate_user!
    before_action :check_client, only: [:add_product, :buy, :remove_product]  # Solo clientes pueden añadir al carrito y comprar

    def show
      @cart = current_user.cart || current_user.create_cart
    end
  
    def add_product
      @cart = current_user.cart || current_user.create_cart
      product = Product.find(params[:product_id])
      @line_item = @cart.line_items.find_or_initialize_by(product: product)
      @line_item.quantity ||= 0
      @line_item.quantity += 1
      @line_item.save
      redirect_to cart_path, notice: 'Producto agregado al carrito.'
    end

    def buy
      @cart = current_user.cart || current_user.create_cart
      redirect_to payment_gateway_path, notice: 'Proceso de compra iniciado.' # Ya está funcionando, solo controlamos los permisos
    end

    def update_item
      line_item = LineItem.find(params[:id])
      if line_item.update(quantity: params[:quantity].to_i)
        redirect_to cart_path, notice: "Cantidad actualizada"
      else
        redirect_to cart_path, alert: "Error al actualizar cantidad"
      end
    end
    
    def remove_product
      @cart = current_user.cart
      product = Product.find(params[:product_id])
      @line_item = @cart.line_items.find_or_initialize_by(product: product)
    
      if @line_item
        @line_item.destroy
        redirect_to cart_path, notice: 'Producto eliminado del carrito.'
      else
        redirect_to cart_path, alert: 'El producto no estaba en el carrito.'
      end
    end
    private

    def check_client
      redirect_to root_path, alert: "No tienes permisos para hacer eso." unless current_user.role == User::CLIENT
    end

  end