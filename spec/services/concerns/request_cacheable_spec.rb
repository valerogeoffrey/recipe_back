# frozen_string_literal: true

# spec/services/cacheable_spec.rb
require 'rails_helper'

RSpec.describe RequestCacheable do
  # classe factice pour inclure le module
  class DummyCache
    include RequestCacheable
  end

  let(:dummy) { DummyCache.new }
  let(:redis_conn) { double('Redis') }

  before do
    stub_const('REDIS_POOL', double('Pool', with: nil))
    allow(REDIS_POOL).to receive(:with).and_yield(redis_conn)
  end

  describe '#cache_ttl' do
    it 'returns default TTL from APP_CONF or 30 seconds' do
      stub_const('APP_CONF', { cache: { ttl: 10 } })
      expect(dummy.send(:cache_ttl)).to eq(10.seconds)

      stub_const('APP_CONF', {})
      expect(dummy.send(:cache_ttl)).to eq(30.seconds)
    end
  end

  describe '#cache_fetch' do
    let(:key) { 'my_key' }

    it 'returns cached value if present in Redis' do
      allow(redis_conn).to receive(:get).with(key).and_return({ foo: 'bar' }.to_json)
      expect(dummy.send(:cache_fetch, key) { raise 'should not be called' }).to eq({ 'foo' => 'bar' })
    end

    it 'yields block and caches result if not present' do
      allow(redis_conn).to receive(:get).with(key).and_return(nil)
      expect(redis_conn).to receive(:setex).with(key, 30.seconds, { foo: 'bar' }.to_json)

      result = dummy.send(:cache_fetch, key) { { foo: 'bar' } }
      expect(result).to eq({ foo: 'bar' })
    end

    it 'respects custom TTL' do
      allow(redis_conn).to receive(:get).with(key).and_return(nil)
      expect(redis_conn).to receive(:setex).with(key, 60, { foo: 'bar' }.to_json)
      dummy.send(:cache_fetch, key, ttl: 60) { { foo: 'bar' } }
    end
  end

  describe '#cache_key_for' do
    it 'generates a unique key based on class name and parts' do
      key = dummy.send(:cache_key_for, 'a', 1)
      expect(key).to start_with('dummy_cache:')
      # clé MD5 stable
      expected_digest = Digest::MD5.hexdigest('a:1')
      expect(key).to eq("dummy_cache:#{expected_digest}")
    end
  end
end
