require 'bunny'
require 'json'
require 'rubyXL'

# Configuración de la conexión a RabbitMQ
connection = Bunny.new('amqp://my-rails-app-rabbitmq-1:5672')
connection.start

channel = connection.create_channel
queue = channel.queue('payments_excel_queue', durable: true)

# Ruta del archivo Excel
file_path = 'compras_de_2025-02-06.xlsx'

# Abre el archivo Excel con rubyXL (lee o crea uno nuevo)
workbook = if File.exist?(file_path)
             RubyXL::Parser.parse(file_path)  # Abre el archivo si existe
           else
             RubyXL::Workbook.new  # Crea uno nuevo si no existe
           end

# Si no existen hojas, crea la hoja
worksheet = workbook.worksheets.first || workbook.add_worksheet('Sheet1')

# Encuentra la última fila ocupada
last_row = worksheet.sheet_data.size

# Comienza a consumir mensajes de RabbitMQ
puts "[*] Esperando mensajes para registrar compras en Excel..."

queue.subscribe(block: true) do |delivery_info, properties, body|
  begin
    # Decodifica el cuerpo del mensaje
    purchase_data = JSON.parse(body)

    # Extrae la información de la compra
    user_id = purchase_data["user_id"]
    email = purchase_data["email"]
    total = purchase_data["total"]
    items = purchase_data["items"]  # Es un arreglo de productos

    # Imprimir para depuración
    puts "Datos de la compra recibidos: #{purchase_data}"

    # Verificar si los datos no están vacíos o nulos antes de agregarlos
    if user_id.nil? || email.nil? || total.nil? || items.nil?
      puts "Error: uno o más datos están vacíos o nulos. Rechazando el mensaje."
    else
      # Procesar cada ítem dentro del arreglo 'items'
      items.each_with_index do |item, index|
        product_name = item["product_name"]
        quantity = item["quantity"]
        price = item["price"]

        # Verifica si los campos dentro de cada ítem no están vacíos
        if product_name.nil? || quantity.nil? || price.nil?
          puts "Error: uno o más datos del producto están vacíos. Ignorando este producto."
        else
          # Agrega los datos a la siguiente fila vacía
          worksheet.add_cell(last_row, 0, product_name.to_s)   # Columna 0 -> product_name
          worksheet.add_cell(last_row, 1, quantity.to_i)       # Columna 1 -> quantity (como entero)
          worksheet.add_cell(last_row, 2, price.to_f)          # Columna 2 -> price (como decimal)(precio por unidad)
          worksheet.add_cell(last_row, 3, total.to_f)          # Columna 3 -> total (como decimal)
          worksheet.add_cell(last_row, 4, email.to_s)          # Columna 4 -> email (como texto)
          worksheet.add_cell(last_row, 5, user_id.to_s)        # Columna 5 -> user_id (como texto)

          # Guarda el archivo Excel
          workbook.write(file_path)

          puts "Producto registrado: #{item}"

          # Incrementa last_row para la próxima fila
          last_row += 1
        end
      end
    end
  rescue => e
    puts "Error procesando el mensaje: #{e.message}"
  end
end