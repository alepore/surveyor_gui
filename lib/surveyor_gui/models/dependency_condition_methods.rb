module SurveyorGui
  module Models
    module DependencyConditionMethods
      extend ActiveSupport::Concern

      included do
        belongs_to :dependency
        default_scope { order('rule_key') }
      end

      def join_operator
        rule = Rules.new(self)
        return rule.join_operator(self.rule_key)
      end

      def join_operator=(x)
      end


      class Rules

        attr_accessor :rules

        def initialize(dependency_condition)
          if dependency_condition.dependency
            @rules = dependency_condition.dependency.rule.split(' ')
          else
            @rules = []
          end
        end

        def join_operator(rule_key)
          _find_join_operator(_find_rule_key(rule_key))
        end

        private

        def _find_rule_key(rule_key)
          rules.index(rule_key)
        end

        def _find_join_operator(idx)
          if idx && idx > 0
            rules[idx-1]
          end
        end
      end

    end
  end
end
