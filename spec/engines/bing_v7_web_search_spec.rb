# frozen_string_literal: true

describe BingV7WebSearch do
  subject { described_class.new(options) }

  it_behaves_like 'a Bing search'
  it_behaves_like 'a web search engine'

  it 'uses the correct host' do
    expect(described_class.api_host).to eq('https://api.bing.microsoft.com')
  end

  it 'uses the correct endpoint' do
    expect(described_class.api_endpoint).to eq('/v7.0/search')
  end

  describe '#hosted_subscription_key' do
    let(:options) { {} }

    before do
      allow(Rails.application.secrets).to receive(:bing_v7).
        and_return({ web_subscription_id: 'web key' })
    end

    it 'uses the web search key' do
      expect(subject.hosted_subscription_key).to eq('web key')
    end
  end

  # This was an edge-case bug on Bing's side:
  # https://www.pivotaltracker.com/story/show/160807845
  # Move this spec to shared bing_search_behavior after Bing V5 and Azure classes are removed
  context 'when a Spanish site runs a search that could return location results' do
    let(:params) do
      { query: 'hotel (site:search.gov)' }
    end

    before { allow(Language).to receive(:bing_market_for_code).and_return('es-US') }

    it 'returns no results' do
      expect(described_class.new(params).execute_query.total).to eq 0
    end
  end
end
