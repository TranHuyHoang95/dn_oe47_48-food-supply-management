RSpec.shared_examples "status cann't change" do |status, message|
  let!(:order){FactoryBot.create :order, status: status}

  before{put :update, xhr: true, params: {id: order.id, status: "processing"}}
  it "display flash message" do
    expect(flash.now[:notice]).to eq I18n.t("admin.order.#{message}")
  end
  it "render update template" do
    expect(response).to render_template("update")
  end
end