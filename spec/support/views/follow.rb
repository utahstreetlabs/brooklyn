shared_examples "has follow button" do
  it "shows the follow button" do
    render
    rendered.should have_selector(".follow-wrap")
  end
end

shared_examples "hasn't follow button" do
  it "does not show the follow button" do
    render
    rendered.should_not have_selector(".follow-wrap")
  end
end
