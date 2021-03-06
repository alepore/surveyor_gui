class DependencysController < ApplicationController

  def new
    prep_variables
    @title = "Add Logic for "+@this_question
    @question.build_dependency(:rule=>'A')
  end

  def edit
    prep_variables
    @title = "Edit Logic for Question "+@this_question
  end

  def create
    @question = Question.new(params[:question])
    if @question.save
      redirect_to :back
    else
      render :action => 'new', :layout=>'colorbox'
    end
  end

  def update
    @title = "Update Question"
    @question = Question.includes(:answers).find(params[:id])
    if @question.update_attributes(params[:question])
      @question.dependency.destroy if @question.dependency.dependency_conditions.blank?
      render :blank, :layout=>'colorbox'
    else
      prep_variables
      render :action => 'edit', :layout=>'colorbox'
    end
  end

  def destroy
    question = Question.find(params[:id])
    question.dependency.destroy
    render :nothing=>true
  end

  def render_dependency_conditions_partial
    prep_variables
    if @question.dependency.nil?
      @question.build_dependency(:rule=>'A').dependency_conditions.build()
    end
    if @question.dependency.dependency_conditions.empty?
      @question.dependency.dependency_conditions.build()
    else
      if params[:add_row]
        @question = Question.new
        @question.build_dependency(:rule=>'A').dependency_conditions.build()
      end
    end
    render :partial => 'dependency_condition_fields'
  end

  def get_answers
    options=""
    question_id =  params[:question_id]
    question = Question.find(question_id)
    if question && question.answers
      question.answers.each_with_index do |a, index|
        options += '<option ' +
         (index == 0 ? 'selected="selected" ' : '') +
         'value="' + a.id.to_s + '"' +
         '>'+a.text.to_s+"</option>"
      end
    end
    render :inline=>options
  end

  def get_question_type
    question_id =  params[:question_id]
    question = Question.find(question_id)
    response=question.pick
    response += ','+question.question_type
    render :inline=>response
  end

private

  def prep_variables
    @question = Question.includes(:dependency).find(params[:id]) unless @question
    controlling_questions = get_controlling_question_collection(@question)
    @controlling_questions = controlling_questions.collection
    @this_question = @question.question_description
    @operators = get_operators
    answers = Question.find(@controlling_questions.last[1]).answers
    @answers = answers.map{|a| [a.text, a.id]}
  end

  def get_controlling_question_collection(dependent_question)
    all_questions_in_survey = _get_all_questions_in_survey(dependent_question)
    _get_question_collection(all_questions_in_survey, dependent_question)
  end

  def _get_all_questions_in_survey(question)
    PossibleControllingQuestion.unscoped
      .joins(:survey_section)
      .where('survey_id = ?', question.survey_section.survey_id)
      .order('survey_sections.display_order','survey_sections.id','questions.display_order')
  end

  def _get_question_collection(all_questions, dependent_question)
    return QuestionCollection.new(dependent_question).add_questions(all_questions)
  end

  def get_operators
    return [
      ['equal to (=)','=='],
      ['not equal to','!='],
      ['less than (<)','<'],
      ['less than or equal to (<=)','<='],
      ['greater than or equal to (>=)','>='],
      ['greater than','>']
    ]
  end
end

class QuestionCollection
  ## QuestionCollection provides a 2 dimensional array consisting of a question id
  ## and a question description.  The collection may be used in a view's select field.
  ##
  ## Its membership is determined by a base question.
  ## The base question is the one from which other questions in the collection are derived.
  ## E.g., in a dependency, the question that is shown or hidden based on the answers to others
  ## is the base question.  It shouldn't show up in the collection.
  ##
  ## Other questions may or may not show up in the collection depending on their eligibility.
  ##
  ## Some questions should have a question number and
  ## some should not. The QuestionCollection numbers questions that should be numbered
  ## and keeps track of the numbering.  If a question is numbered, the question number
  ## is included in the description, e.g. "3) What is your name?".  Otherwise,
  ## the description is just the question text, e.g. "Don't forget to use your middle initial".
  ##
  ## Incoming questions may be duck typed, but should respond to is_numbered? and is_eligible?
  ## messages.

  attr_accessor :collection, :dependency_question_description

  def initialize(base_question)
    @collection = []
    @question_number = 1
    @base_question = base_question
    @dependency_question_description = nil
  end

  def collection
    @collection
  end

  def add_questions(questions)
    questions.each {|q| add_question(q)}
    return self
  end

  def add_question(question)
    _add_to_collection_if_eligible(question)
    _increment_question_number if question.is_numbered?
    return self
  end

  private

  def _get_description(question)
    @question_number.to_s + ') ' + question.text
  end

  def _add_to_collection(question)
    description = _get_description(question)
    @collection.push([description, question.id])
  end

  def _add_to_collection_if_eligible(question)
    _add_to_collection(question) if question.is_eligible? && _this_is_not_the_base_question?(question)
  end

  def _this_is_not_the_base_question?(question)
    question.id != @base_question.id
  end

  def _increment_question_number
    @question_number += 1
  end
end

## This shouldn't be here but breaks saving nested attributes on question when put
## in QuestionMethods.  Not sure why, but leave for now and revisit later.
class PossibleControllingQuestion < Question
  def is_eligible?
    question_type!='Label' && question_type!='File Upload'
  end
end
