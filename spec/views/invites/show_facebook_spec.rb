require "spec_helper"

describe "invites/show_facebook" do
  let(:inviters) { [inviter('Bumble')] }
  before(:each) do
    act_as_rfb
    assign(:profile, stub('profile', first_name: 'Cornelius'))
    assign(:inviters, inviters)
    assign(:friends, [])
    view.stubs(:auth_path).returns('/')
    render
  end

  it "shows one inviter" do
    rendered.should have_content('Welcome, Cornelius')
    rendered.should have_content("Bumble believes it's imperative that you join Copious ASAP.")
  end

  context "with many inviters" do
    let(:inviters) { [inviter('Bumble'), inviter('Matlock'), inviter('Voltron')] }
    it "shows many inviters" do
      rendered.should have_content('Welcome, Cornelius')
      rendered.should have_content("Bumble, Matlock, and Voltron invited you to join Copious, you popular person.")
    end
  end

  def inviter(first_name)
    stub("#{first_name} the inviter", typed_photo_url: '', name: '',
      network: 'facebook', profile_url: '', first_name: first_name)
  end
end
