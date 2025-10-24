# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::RecipesController, type: :controller do
  let!(:recipe1) { create(:recipe, default_title: 'Pasta Carbonara') }
  let!(:recipe2) { create(:recipe, default_title: 'Chicken Tikka') }
  let!(:ingredient) { create(:ingredient) }

  describe 'GET #index' do
    context 'with valid parameters' do
      it 'returns recipes successfully' do
        get :index, params: {
          pagination: { page: 1, per_page: 10 },
          filter: { title: 'pasta' }
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['recipes']).to be_an(Array)
      end
    end

    context 'with invalid pagination parameters' do
      it 'overrides params for negative page to 1' do
        get :index, params: { pagination: { page: -1 } }

        expect(response).to have_http_status(:ok)
      end

      it 'overrides params to app_conf > max_per_page' do
        get :index, params: { pagination: { per_page: 2_000_000_000 } }

        expect(response).to have_http_status(:ok)
      end

      it 'return an empty result' do
        get :index, params: { pagination: { page: 20_000 } }

        expect(response).to have_http_status(:ok)
        expect(json_response['recipes']).to eq([])
      end
    end

    context 'with invalid filter parameters' do
      it 'returns error for too long title' do
        long_title = 'a' * 201
        get :index, params: { filter: { title: long_title } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('title_is_too_long')
      end

      it 'returns error for invalid characters in title' do
        get :index, params: { filter: { title: '<script>' } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('title_contain_invalid_chars')
      end

      it 'returns error for too many ingredient IDs' do
        ingredient_ids = (1..51).to_a
        get :index, params: { filter: { ingredient_ids: ingredient_ids } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('too_many_ingredient_ids')
      end

      it 'returns error for invalid ingredient IDs' do
        get :index, params: { filter: { ingredient_ids: [-1, 2, 'abcded'] } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('invalid_ingredient_ids')
      end
    end

    context 'with invalid sort parameters' do
      it 'returns error for invalid sort option' do
        get :index, params: { sort: { by: 'invalid_sort' } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('invalid_sort_options')
      end
    end
  end

  describe 'GET #show' do
    context 'with valid recipe ID' do
      it 'returns recipe successfully' do
        get :show, params: { id: recipe1.id }

        expect(response).to have_http_status(:ok)
        expect(json_response['recipe']['id']).to eq(recipe1.id)
      end
    end

    context 'with invalid recipe ID format' do
      it 'returns error for non-numeric ID' do
        get :show, params: { id: 'abc' }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('Invalid recipe ID format')
      end

      it 'returns error for negative ID' do
        get :show, params: { id: -1 }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('Invalid recipe ID format')
      end
    end

    context 'with non-existent recipe ID' do
      it 'returns not found error' do
        get :show, params: { id: 99_999 }

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('not_found')
      end
    end
  end

  describe 'common parameter validation' do
    it 'includes the api::parameterValidation' do
      expect(controller.class.included_modules).to include(Api::ParameterValidation)
    end
  end

  private

  def json_response
    response.parsed_body
  end
end
