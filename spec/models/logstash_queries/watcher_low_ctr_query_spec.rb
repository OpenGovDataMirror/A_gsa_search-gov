# frozen_string_literal: true

describe WatcherLowCtrQuery do
  let(:query_args) do
    {
      affiliate_name: 'affiliate_name',
      time_window: '1w',
      min_doc_count: 50,
      query_blocklist: 'foo, bar, baz biz'
    }
  end
  let(:query) { described_class.new(query_args) }
  let(:reduce_script) do
    <<~SCRIPT.strip
      int clicks = 0;
      int searches = 0;
      for (agg in states){
        clicks += agg.click ;
        searches += agg.search
      }
      double ctr = searches == 0 ? 0 : 100.0 * clicks / searches; ctr
    SCRIPT
  end
  let(:expected_body) do
    {
      "query": {
        "bool": {
          "filter": [
            {
              "term": {
                "params.affiliate": "affiliate_name"
              }
            },
            {
              "terms": {
                "type": ["search", "click"]
              }
            },
            {
              "exists": {
                "field": "modules"
              }
            },
            {
              "range": {
                "@timestamp": {
                  "gte": "{{ctx.trigger.scheduled_time}}||-1w",
                  "lte": "{{ctx.trigger.scheduled_time}}"
                }
              }
            }
          ],
          "must_not": [
            {
              "term": {
                "useragent.device": "Spider"
              }
            },
            {
              "term": {
                "params.query.raw": ""
              }
            },
            {
              "term": {
                "modules": "QRTD"
              }
            },
            {
              "terms": {
                "params.query.raw": [
                  "foo",
                  "bar",
                  "baz biz"
                ]
              }
            }
          ]
        }
      },
      "aggs": {
        "agg": {
          "terms": {
            "min_doc_count": 50,
            "size": 5000,
            "field": "params.query.raw"
          },
          "aggs": {
            "ctr": {
              "scripted_metric": {
                "init_script": {
                  "source": "state['click'] = state['search'] = 0"
                },
                "map_script": {
                  "source": "state[doc['type'].value] += 1"
                },
                "reduce_script": {
                  "source": reduce_script
                },
                "combine_script": "return state"
              }
            }
          }
        }
      }
    }.to_json
  end

  it_behaves_like 'a watcher query'
end
