module QuestionHelper
  def link_to_remove_fields (name, f)
    f.hidden_field(:_destroy) + link_to(image_tag("delete.png",:border => 0, :margin=>'-1em'), "#", onclick: "remove_fields(this);")
  end
end
