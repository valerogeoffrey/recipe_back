# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Ingredients', type: :request do
  let(:body) { response.parsed_body }

  before do
    allow_any_instance_of(RequestCacheable).to receive(:cache_fetch) { |_, &block| block.call }
  end

  describe 'GET /api/v1/ingredients' do
    let!(:tomato) do
      create(
        :ingredient,
        default_name: 'Tomato'
      )
    end

    let!(:carrot) do
      create(
        :ingredient,
        default_name: 'Carrot'
      )
    end

    context 'without filters' do
      it 'returns all ingredients' do
        get '/api/v1/ingredients'

        expect(response).to have_http_status(:ok)
        expect(body['ingredients'].size).to eq(2)
      end
    end

    context 'with name filter' do
      it 'returns only matching ingredients' do
        get '/api/v1/ingredients', params: { filter: { name: 'Carrot' } }

        expect(body['ingredients'].size).to eq(1)

        names = body['ingredients'].pluck('name')
        expect(names).to eq(['Carrot'])
      end
    end

    context 'with pagination' do
      it 'returns paginated results' do
        get '/api/v1/ingredients', params: { options: { paginate: true }, pagination: { page: 1, per_page: 1 } }
        expect(body['ingredients'].size).to eq(1)
      end

      it 'returns second page' do
        get '/api/v1/ingredients', params: { options: { paginate: true }, pagination: { page: 2, per_page: 1 } }
        expect(body['ingredients'].size).to eq(1)
      end

      it 'returns multiple elements' do
        get '/api/v1/ingredients', params: { pagination: { page: 1, per_page: 2 } }
        expect(body['ingredients'].size).to eq(2)
      end

      it 'returns disable pagination' do
        get '/api/v1/ingredients', params: { pagination: { page: 1, per_page: 1 } }
        expect(body['ingredients'].size).to eq(1)
      end
    end
  end
end
