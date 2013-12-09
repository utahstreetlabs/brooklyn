module Admin
  module AnnotationsIntegrationHelpers
    shared_context "annotations admin" do
      def add_annotation
        within_annotations do
          fill_in 'annotation[url]', with: url
          find('[data-role=new]').click
        end
      end

      def should_have_annotation
        within_annotations do
          page.should have_css('[data-role=annotation]', text: url)
        end
      end

      def within_annotations(&block)
        within '[data-role=annotations]', &block
      end
    end
  end
end

RSpec.configure do |config|
  config.include Admin::AnnotationsIntegrationHelpers
end
