require 'sinatra'
require 'prawn'
require 'prawn/table'
require 'date'

set :bind, '0.0.0.0'

helpers do
  def format_price(amount)
    "$#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} USD"
  end
end

get '/' do
  erb :form
end

post '/generate' do
  content_type 'application/pdf'

  plan = params[:selected_plan]
  display_plan = plan == "Basecamp Pro Unlimited ACH Invoice" ? "Basecamp Pro Unlimited ACH Invoice" : plan
  price = params[:price]
  user_count = params[:user_count]

  if plan == "Basecamp Plus Monthly" && user_count
    price = "$#{15 * user_count.to_i} USD per month"
    display_plan += " (#{user_count} users)"
  elsif plan == "Basecamp Pro Unlimited ACH Invoice"
    price = format_price(3588)
  elsif plan == "Basecamp Pro Unlimited Monthly"
    price = "$349 USD per month"
  end

  # Adjust Plan Label
  plan_label = ["Lump Sum Deposit", "Basecamp Pro Unlimited ACH Invoice"].include?(plan) ? "#{display_plan}" : "Plan: #{display_plan}"

  pdf = Prawn::Document.new
  pdf.font_families.update("Inter" => {
    normal: "fonts/Inter-Regular.ttf",
    bold: "fonts/Inter-Bold.ttf"
  })
  pdf.font("Inter")

  pdf.image("logo.png", width: 200, position: :center) if File.exist?("logo.png")
  pdf.move_down 30

  # First Box: Account Details
  generated_quote = "#{params[:account]}-25"
  data = [
    ["Quote:", generated_quote, "Account:", params[:account]],
    ["Date:", params[:date], "Account Name:", params[:account_name]],
    ["Next Billing Date:", params[:next_billing], "Account Owner:", params[:account_owner]],
    ["Owner's Email:", params[:account_owner_email], "", ""]
  ]

  pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width) do
    pdf.table(data,
      cell_style: { borders: [], padding: [4, 4, 4, 4] },
      column_widths: [140, 150, 130, pdf.bounds.width - 420]
    ) do
      row(0..-1).columns(0).font_style = :bold
      row(0..-1).columns(2).font_style = :bold
    end
    pdf.stroke_bounds
  end
  pdf.move_down 30

  # Second Box: Plan and Price
  pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width) do
    plan_data = [[
      { content: plan_label, font_style: :bold, size: 14 },
      { content: "Price: #{price}", font_style: :bold, size: 14 }
    ]]
    pdf.table(plan_data, width: pdf.bounds.width / 1.2, position: :center,
              cell_style: { borders: [], padding: [1, 8, 6, 8], align: :left }) do
      cells.border_width = 0
    end
    pdf.stroke_bounds
  end
  pdf.move_down 30

  # Box 3: Pro Unlimited Features
  if ["Basecamp Pro Unlimited Monthly", "Basecamp Pro Unlimited Yearly", "Basecamp Pro Unlimited ACH Invoice"].include?(plan)
    features = [
      "Extended 60-day free trial",
      "Fixed price no per-user charges",
      "Unlimited projects",
      "5 terabytes storage space",
      "Priority 24/7/365 customer support",
      "Includes Timesheet upgrade",
      "Includes Admin Pro Pack upgrade",
      "Personal onboarding with our team",
      "Billed in one lump sum annually for simplified accounting."
    ]
    pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width) do
      pdf.indent(10) do
        pdf.text "Included Features:", style: :bold
        pdf.move_down 5
        features.each do |f|
          pdf.text "• #{f}", size: 11, align: :left, leading: 2
        end
      end
      pdf.move_down 10
      pdf.stroke_bounds
    end
    pdf.move_down 30
  end

  # Box 3a: Basecamp Plus Monthly Features
  if plan == "Basecamp Plus Monthly"
    features = [
      "Pay-per-user pricing",
      "Unlimited projects",
      "500 GB storage space",
      "24/7/365 customer support",
      "Purchase optional Timesheet and Admin Pro Pack upgrades",
      "Month-to-month billing"
    ]
    pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width) do
      pdf.indent(10) do
        pdf.text "Included Features:", style: :bold
        pdf.move_down 5
        features.each do |f|
          pdf.text "• #{f}", size: 11, align: :left, leading: 2
        end
      end
      pdf.move_down 10
      pdf.stroke_bounds
    end
    pdf.move_down 30
  end

  # Box 3b: Lump Sum Info
  if plan == "Lump Sum Deposit"
    bullets = [
      "A lump sum payment will credit your account with that amount. Our billing system will pull from that credit each month before ever charging the card on file.",
      "The owner will receive a paid invoice at the point of the lump sum payment and each month after. All paid invoices can be found by any account owner in Adminland.",
      "Taxes depend on the address of the card added to the account: 37signals.com/policies/taxes.",
      "Terms of Service: 37signals.com/policies/terms"
    ]
    pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width) do
      pdf.indent(10) do
        pdf.text "Lump Sum Details:", style: :bold
        pdf.move_down 5
        bullets.each do |b|
          if b.include?("37signals.com/policies/taxes")
            pdf.formatted_text [
              { text: "• Taxes depend on the address of the card added to the account: ", size: 11 },
              { text: "37signals.com/policies/taxes", size: 11, styles: [:underline] }
            ], align: :left, leading: 2
          elsif b.include?("37signals.com/policies/terms")
            pdf.formatted_text [
              { text: "• Terms of Service: ", size: 11 },
              { text: "37signals.com/policies/terms", size: 11, styles: [:underline] }
            ], align: :left, leading: 2
          else
            pdf.text "• #{b}", size: 11, align: :left, leading: 2
          end
        end
      end
      pdf.move_down 10
      pdf.stroke_bounds
    end
    pdf.move_down 30
  end

  # Box 4a: Shown for Pro Unlimited Monthly, Pro Unlimited Yearly, and Basecamp Plus Monthly
  if ["Basecamp Pro Unlimited Monthly", "Basecamp Pro Unlimited Yearly", "Basecamp Plus Monthly"].include?(plan)
    bullets = [
      "Payment must be made via a credit or debit card inside the Basecamp account by an Account Owner.",
      "Basecamp.com is the sole source for purchasing Basecamp.",
      "Terms of Service: 37signals.com/policies/terms"
    ]
    pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width) do
      pdf.indent(10) do
        pdf.text "Additional Notes:", style: :bold
        pdf.move_down 5
        bullets.each do |b|
          if b.include?("37signals.com/policies/terms")
            pdf.formatted_text [
              { text: "• Terms of Service: ", size: 11 },
              { text: "37signals.com/policies/terms", size: 11, styles: [:underline] }
            ], align: :left, leading: 2
          else
            pdf.text "• #{b}", size: 11, align: :left, leading: 2
          end
        end
      end
      pdf.move_down 10
      pdf.stroke_bounds
    end
    pdf.move_down 30
  end

  # Fourth Box: Payment Instructions (for ACH only)
  if plan == "Basecamp Pro Unlimited ACH Invoice"
    pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width) do
      left = [
        { content: "Payable to", font_style: :bold },
        "37signals, LLC",
        "137 N Oak Park Ave",
        "Suite 208",
        "Oak Park, IL 60301"
      ]
      right = [
        { content: "Wire Transfer", font_style: :bold },
        "Account: 709576128",
        "Routing: 071000013",
        "SWIFT: CHASUS33",
        "JPMorgan Chase",
        "10 South Dearborn",
        "Floor 11",
        "Chicago, IL 60603"
      ]
      data = [[
        pdf.make_table(left.map { |line| [line] }, cell_style: { borders: [], padding: [2, 4] }),
        pdf.make_table(right.map { |line| [line] }, cell_style: { borders: [], padding: [2, 4] })
      ]]
      pdf.table(data, width: pdf.bounds.width, cell_style: { borders: [] })
pdf.move_down 10  # adds space inside the box before the border
pdf.stroke_bounds
    end
    pdf.move_down 30
  end

  # Fifth box: Support message
  pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width) do
    box_height = 30
    pdf.stroke_rectangle [pdf.bounds.left, pdf.cursor], pdf.bounds.width, box_height
    pdf.move_down 7
    pdf.indent(20) do
      pdf.text "Questions? Visit basecamp.com/support", size: 11, style: :bold, align: :center
    end
  end

  attachment "#{params[:account]}-quote.pdf"
  pdf.render
end