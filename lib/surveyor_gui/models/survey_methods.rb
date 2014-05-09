module SurveyorGui
  module Models
    module SurveyMethods
      extend ActiveSupport::Concern

      included do
        extend Surveyor::Models::SurveyMethods

        has_many :survey_sections, :dependent => :destroy
        accepts_nested_attributes_for :survey_sections, :allow_destroy => true

        validate :no_responses
        before_destroy :no_responses
      end


      #don't let a survey be deleted or changed if responses have been submitted
      #to ensure data integrity
      def no_responses
        if self.id
          #this will be a problem if two people are editing the survey at the same time and do a survey preview - highly unlikely though.
          self.response_sets.where('test_data = ?',true).each {|r| r.destroy}
        end
        if !template && response_sets.count>0
          errors.add(:base,"Reponses have already been collected for this survey, therefore it cannot be modified. Please create a new survey instead.")
          return false
        end
      end

    end
  end
end
