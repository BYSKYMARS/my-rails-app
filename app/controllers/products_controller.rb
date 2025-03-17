class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update destroy ]
  before_action :authenticate_user!
  before_action :check_admin, only: [:edit, :update, :destroy, :create]  # Solo admin puede estas acciones

  # GET /products or /products.json
  def index
    if params[:query].present?
      @products = Product.where("nombre ILIKE ?", "%#{params[:query]}%")
    else
      @products = Product.all
    end
  end

  # GET /products/1 or /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products or /products.json
  def create
    @product = Product.new(product_params)
  
    # Depuración para verificar que el archivo de imagen esté llegando
    puts product_params[:imagen_referencial]
  
    if @product.save
      redirect_to @product, notice: "Producto creado correctamente."
    else
      # Ver los errores si no se guarda el producto
      puts @product.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  end
  

  # PATCH/PUT /products/1 or /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: "Product was successfully updated." }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1 or /products/1.json
  def destroy
    @product.destroy!

    respond_to do |format|
      format.html { redirect_to products_path, status: :see_other, notice: "Product was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def check_admin
       redirect_to root_path, alert: "No tienes permisos para hacer eso." unless current_user.role == User::ADMIN
    end
    
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.require(:product).permit(:nombre, :descripcion, :stock, :precio, :imagen_referencial, :marca)
    end
end
