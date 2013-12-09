require 'spec_helper'

describe SecretSellerItemMailer do
  let(:item) { FactoryGirl.create(:secret_seller_item) }

  it "builds a submitted message" do
    msg = SecretSellerItemMailer.submitted(item.id)
    expect(msg.attachments).to have(1).attachment
    expect(msg.attachments.first.filename).to eq(item.photo.filename)
  end
end
