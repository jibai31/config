module Api
  module V1
    class TastingsController < ApplicationController
      def index
        tastings = current_user.tastings.includes(:card).order(tasted_on: :desc, created_at: :desc)
        tastings = tastings.where(card_id: params[:card_id]) if params[:card_id].present?
        render json: tastings.as_json(include: :card)
      end

      def update
        tasting = current_user.tastings.find(params[:id])
        if tasting.update(tasting_params)
          render json: tasting
        else
          render json: { errors: tasting.errors }, status: :unprocessable_entity
        end
      end

      private

      def tasting_params
        params.require(:tasting).permit(:notes, :rating, :tasted_on)
      end
    end
  end
end
