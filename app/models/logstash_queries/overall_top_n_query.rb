# frozen_string_literal: true

class OverallTopNQuery
  include AnalyticsDsl

  def initialize(since, agg_options = {})
    @since = since
    @agg_options = agg_options
  end

  def body
    Jbuilder.encode do |json|
      filter_booleans(json)
      terms_agg(json, @agg_options)
    end
  end

  def booleans(json)
    json.must_not do
      json.term { json.tags 'api' }
    end
    json.filter do
      since(json, @since)
    end
  end
end
