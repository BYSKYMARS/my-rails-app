json.extract! product, :id, :nombre, :descripcion, :stock, :precio, :imagen_referencial, :marca, :created_at, :updated_at
json.url product_url(product, format: :json)
