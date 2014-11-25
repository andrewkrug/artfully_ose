#
# This has to be included after the searchable block in your model
#
module Ext
  module DelayedIndexing
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        handle_asynchronously :solr_index
        handle_asynchronously :solr_index!
        after_commit { Sunspot.delay.commit }
      end
    end

    module ClassMethods
      def search_index(query, organization)
        self.search do
          fulltext query
          with(:organization_id).equal_to(organization.id)
        end.results
      end
    end
  end
end