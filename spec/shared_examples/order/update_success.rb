RSpec.shared_examples "when update success" do |status|
  it "update db success" do
    expect(order.status).to eq status
  end
  it "display flash message" do
    expect(flash[:notice]).to eq I18n.t("admin.order.update_sc")
  end
  it "render update template" do
    expect(response).to render_template("update")
  end
end
