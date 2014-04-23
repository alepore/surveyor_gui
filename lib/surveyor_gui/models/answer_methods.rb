module SurveyorGui
  module Models
    module AnswerMethods
      extend ActiveSupport::Concern

      included do
        belongs_to :question
        has_many :responses
      end

      def split_or_hidden_text(part = nil)
        #return "" if hide_label.to_s == "true"
        return "" if display_type.to_s == "hidden_label"
        part == :pre ? text.split("|",2)[0] : (part == :post ? text.split("|",2)[1] : text)
      end

    end
  end
end
