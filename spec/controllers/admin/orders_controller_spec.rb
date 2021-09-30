require "rails_helper"
include SessionsHelper

RSpec.describe Admin::OrdersController, type: :controller do
  describe "GET #index" do
    let(:admin){FactoryBot.create :user, role: "admin"}
    let!(:buyer){FactoryBot.create :user, role: "buyer"}
    let!(:order){FactoryBot.create :order}
    let(:wrong_status){Faker::Name.name}
    it_behaves_like "when user hasn't logged in" 
    context "when user logged in" do
      it_behaves_like "when user isn't admin"
      context "when user is admin" do
        before{log_in admin}
        it "assign @orders matched" do
          get :index
          expect(assigns(:orders)).to eq([order])
        end
        it "render the index template" do
          get :index, xhr: true
          expect(response).to render_template("index")
        end
      end
    end
  end

  describe "PUT #update" do
    let(:admin){FactoryBot.create :user, role: "admin"}
    let!(:buyer){FactoryBot.create :user, role: "buyer"}
    let!(:order){FactoryBot.create :order, status: "processing"}
    let!(:order_shipped){FactoryBot.create :order, status: "shipped"}
    let!(:product){FactoryBot.create :product, quantity: 30}
    let!(:order_product){
      FactoryBot.create :order_product,
        product_id: product.id,
        order_id: order.id,
        quantity: 4
    }
    let!(:new_quantity){order_product.quantity + product.quantity}

    it_behaves_like "when user hasn't logged in" 
    context "when user logged in" do
      it_behaves_like "when user isn't admin"
      context "when user is admin" do
        before{log_in admin}

        context "success when valid attributes" do
          it "assign @order exists" do
            put :update, xhr: true, params: {id: order.id, status: "processing"}
            expect(assigns(:order)).to eq order
          end

          context "when update failed" do
            context "fail when status cann't change" do
              context "when status order: canceled" do
                it_behaves_like "status cann't change", "canceled", "update_cant_change"
              end

              context "when status order: completed" do
                it_behaves_like "status cann't change", "completed", "update_cant_change"
              end

              context "when status order: shipped" do
                it_behaves_like "status cann't change", "shipped", "update_pre"
              end

              context "change to completed when it hasn't shipped" do
                before{put :update, xhr: true, params: {id: order.id, status: "completed"}}
                it "display flash message" do
                  expect(flash.now[:notice]).to eq I18n.t("admin.order.update_not_ship")
                end
                it "render update template" do
                  expect(response).to render_template("update")
                end
              end
            end

          context "when update successfully" do
            context "when update to shipped" do
              before do
                put :update, xhr: true, params: {id: order.id, status: "shipped"}
                order.reload
              end
             it_behaves_like "when update success", "shipped"
            end

            context "when update to canceled" do
              before do
                put :update, xhr: true, params: {id: order.id, status: "canceled"}
                order.reload
              end
              context "restore product's quantity" do
                it "when product not found" do
                  order.order_products.each do |o_p|
                    o_p.product = nil
                  end
                end
                it "when restore success" do
                  order.order_products.each do |o_p|
                    product.update(quantity: new_quantity)
                    order_product.reload
                    expect(order_product.product_quantity).to eq new_quantity
                  end
                end
              end
              it_behaves_like "when update success", "canceled"
            end
          end
          end
        end

        context "fail when order not found" do
          before do
            put :update, xhr: true,
              params: {id: -1}
          end

          it "display flash message" do
            expect(flash[:danger]).to eq I18n.t("admin.order.nil")
          end
          it "redirect to admin root path" do
            expect(response).to redirect_to admin_root_path
          end
        end
      end
    end
  end
end
