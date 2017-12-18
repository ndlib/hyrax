module Hyrax
  module Statistics
    module Works
      class ByResourceType < Statistics::TermQuery
        private

          def index_key
            Solrizer.solr_name("resource_type", :symbol)
          end
      end
    end
  end
end
