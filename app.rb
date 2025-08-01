require 'sinatra'
require 'prawn'
require 'prawn/table'
require 'date'

set :bind, '0.0.0.0'
set :port, ENV['PORT'] || 4567
set :environment, :production
set :protection, false
set :public_folder, 'public'
set :views, 'views'
set :allow_origin, '*'

disable :show_exceptions

get '/' do
  erb :form
end

post '/generate' do
  content_type 'application/pdf'

  pdf = Prawn::Document.new

  pdf.font_families.update("Inter" => {
  normal: "fonts/static/Inter_18pt-Regular.ttf",
  bold: "fonts/static/Inter_18pt-Bold.ttf"
})

  pdf.font("Inter")

  # Logo
  if File.exist?("logo.png")
    pdf.image "logo.png", width: 100, position: :center
    pdf.move_down 20
  end

  # First box: Account details
  pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width, height: 100) do
    data = [
      [
        { content: "Quote:", font_style: :bold }, "#{params[:quote]}-25",
        { content: "Account:", font_style: :bold }, params[:account]
      ],
      [
        { content: "Date:", font_style: :bold }, params[:date],
        { content: "Account Name:", font_style: :bold }, params[:account_name]
      ],
      [
        { content: "Next Billing Date:", font_style: :bold }, params[:next_billing],
        { content: "Account Owner:", font_style: :bold }, params[:account_owner]
      ]
    ]

    pdf.table(data, cell_style: { borders: [] }, width: pdf.bounds.width) do
      cells.padding = 8
      cells.border_width = 0
      self.cell_style = { inline_format: true }
    end

    pdf.stroke_bounds
  end

  pdf.move_down 40

  # Second box: Plan and Price
  plan = params[:selected_plan]
  price = params[:price]
  user_count = params[:user_count]

  if plan == "Basecamp Plus Monthly" && user_count
    price = "$#{15 * user_count.to_i}"
  end

  pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width, height: 50) do
    plan_data = [
      [
        { content: "Plan:", font_style: :bold }, plan,
        { content: "Price:", font_style: :bold }, "#{price} USD"
      ]
    ]

    pdf.table(plan_data, cell_style: { borders: [] }, width: pdf.bounds.width) do
      cells.padding = 8
      cells.border_width = 0
      self.cell_style = { inline_format: true }
    end

    pdf.stroke_bounds
  end

  attachment "quote.pdf"
  pdf.render
end
