# frozen_string_literal: true

require 'google/cloud/firestore'

# Google Firestore
def firestore
  @firestore ||= Google::Cloud::Firestore.new project_id: 'xwds-368015'
end
