# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::IngredientsController, type: :controller do
  let!(:ingredient1) { create(:ingredient, default_name: 'Tomato') }
  let!(:ingredient2) { create(:ingredient, default_name: 'Carrot') }
  let!(:ingredient3) { create(:ingredient, default_name: 'Onion') }

  describe 'GET #index' do
    context 'with valid parameters' do
      it 'returns ingredients successfully' do
        get :index, params: {
          pagination: { page: 1, per_page: 10 },
          filter: { name: 'tomato' }
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
        expect(json_response['ingredients'].size).to eq(1)
      end

      it 'returns ingredients without filters' do
        get :index, params: {
          pagination: { page: 1, per_page: 10 }
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end

      it 'returns ingredients with ids filter' do
        get :index, params: {
          filter: { ids: [ingredient1.id, ingredient2.id] }
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end

      it 'returns ingredients with both name and ids filters' do
        get :index, params: {
          filter: { name: 'tomato', ids: [ingredient1.id] }
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
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

      it 'returns an empty result for very high page number' do
        get :index, params: { paginate: true, pagination: { page: 20_000 } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to eq([])
      end
    end

    context 'with invalid filter parameters' do
      it 'returns error for too long name' do
        long_name = 'a' * 101
        get :index, params: { filter: { name: long_name } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('name_is_too_long')
      end

      it 'returns error for invalid characters in name' do
        get :index, params: { filter: { name: '<script>' } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('name_contain_invalid_chars')
      end

      it 'returns error for name with double quotes' do
        get :index, params: { filter: { name: 'ingredient"test' } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('name_contain_invalid_chars')
      end

      it 'returns error for name with single quotes' do
        get :index, params: { filter: { name: "ingredient'test" } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('name_contain_invalid_chars')
      end

      it 'returns error for name with ampersand' do
        get :index, params: { filter: { name: 'ingredient & test' } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('name_contain_invalid_chars')
      end

      it 'returns error for too many ingredient IDs' do
        ingredient_ids = (1..51).to_a
        get :index, params: { filter: { ids: ingredient_ids } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('too_many_ingredient_ids')
      end

      it 'returns error for invalid ingredient IDs format' do
        get :index, params: { filter: { ids: [-1, 2, 'abcded'] } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('invalid_ingredient_ids')
      end

      it 'transforms ids front string into 0' do
        get :index, params: { filter: { ids: %w[abc def] } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to eq([])
      end

      it 'transforms ids front string containing special characters into 0' do
        get :index, params: { filter: { ids: ['1@2', '3#4'] } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to eq([])
      end

      it 'returns multiple errors for combined invalid filters' do
        long_name = 'a' * 101
        ingredient_ids = (1..51).to_a
        get :index, params: {
          filter: { name: "#{long_name}<>", ids: ingredient_ids + ['invalid'] }
        }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('name_is_too_long')
        expect(json_response['details']).to include('name_contain_invalid_chars')
        expect(json_response['details']).to include('too_many_ingredient_ids')
      end
    end

    context 'with invalid sort parameters' do
      it 'returns error for invalid sort option' do
        get :index, params: { sort: { by: 'invalid_sort' } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('invalid_sort_options')
      end

      it 'returns error for non-whitelisted sort option' do
        get :index, params: { sort: { by: 'created_at' } }

        expect(response).to have_http_status(:bad_request)
        expect(json_response['details']).to include('invalid_sort_options')
      end
    end

    context 'with edge cases' do
      it 'handles empty name filter by ignoring it' do
        get :index, params: { filter: { name: '' } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end

      it 'handles name with whitespace only by ignoring it' do
        get :index, params: { filter: { name: '   ' } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end

      it 'handles empty ids array' do
        get :index, params: { filter: { ids: [] } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end

      it 'strips whitespace from name filter' do
        get :index, params: { filter: { name: '  tomato  ' } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end

      it 'removes duplicate ids from filter' do
        get :index, params: { filter: { ids: [1, 1, 2, 2, 3] } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end

      it 'converts string ids to integers' do
        get :index, params: { filter: { ids: %w[1 2 3] } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end
    end

    context 'with sorting' do
      it 'returns ingredients with valid sort option' do
        get :index, params: { sort: { by: 'title_asc' } }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end
    end

    context 'with combined valid parameters' do
      it 'handles all parameters together' do
        get :index, params: {
          filter: { name: 'tomato', ids: [ingredient1.id, ingredient2.id] },
          pagination: { page: 1, per_page: 10 },
          sort: { by: 'title_asc' }
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['ingredients']).to be_an(Array)
      end
    end
  end

  describe 'common parameter validation' do
    it 'includes the Api::ParameterValidation module' do
      expect(controller.class.included_modules).to include(Api::ParameterValidation)
    end
  end

  describe 'before_action callbacks' do
    it 'validates pagination on index action' do
      expect(controller).to receive(:validate_pagination!).and_call_original
      get :index
    end

    it 'validates sort on index action' do
      expect(controller).to receive(:validate_sort!).and_call_original
      get :index
    end

    it 'validates ingredient filters on index action' do
      expect(controller).to receive(:validate_ingredient_filters!).and_call_original
      get :index
    end
  end

  private

  def json_response
    response.parsed_body
  end
end
