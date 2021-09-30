class Admin::OrdersController < Admin::AdminsController
  before_action :load_orders, only: :index
  before_action :load_order, :update_with_message, only: :update

  def index; end

  def update
    restore_products_quantity(@order) if @message_key == "update_sc"
    respond_to do |format|
      format.js{flash.now[:notice] = t "admin.order.#{@message_key}"}
    end
  end

  private

  def load_order
    @order = Order.find_by id: params[:id]
    return if @order

    flash[:danger] = t "admin.order.nil"
    redirect_to admin_root_path
  end

  def load_orders
    @orders = Order.includes(order_products: :product)
                   .order_by_status.page(params[:page])
                   .per(Settings.per_page.per_5)
  end

  def restore_products_quantity order
    return unless order.canceled?

    order.order_products.each do |o_p|
      next unless o_p.product

      product_quantity_new = o_p.quantity + o_p.product_quantity
      o_p.product.update(quantity: product_quantity_new)
    end
  end

  def update_with_message
    p_status = params[:status]
    message_arr = check_message_case(@order, p_status).find{|_key, value| value}
    return @message_key = message_arr[0] if message_arr

    return @message_key = "update_sc" if @order.update(status: p_status)
  end

  def check_message_case order, p_status
    {
      update_cant_change: cant_change?(order),
      update_pre: cant_update_previous?(order, p_status),
      update_not_ship: order_hasnt_ship?(order, p_status)
    }
  end

  def cant_change? order
    order.canceled? || order.completed?
  end

  def cant_update_previous? order, p_status
    Order.statuses[p_status] < Order.statuses[order.status]
  end

  def order_hasnt_ship? order, p_status
    p_status == "completed" && order.processing?
  end
end
