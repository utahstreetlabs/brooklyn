module DatagridHelpers
  def search_datagrid(query)
    within 'form.datagrid-search' do
      fill_in 'query', with: query
      click_on 'Search'
    end
  end
end

RSpec.configure do |config|
  config.include DatagridHelpers
end
