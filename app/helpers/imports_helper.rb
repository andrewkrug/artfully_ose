module ImportsHelper

  def import_page_controller import, offset, length
    if offset > 0
      left_path = import_path import, :offset => [ 0, offset - length ].max, :length => length
      left_classes = "previous btn"
    else
      left_path = "#"
      left_classes = "previous btn disabled"
    end

    if offset + length < import.rows.count
      right_path = import_path import, :offset => offset + length, :length => length
      right_classes = "next btn pull-right"
    else
      right_path = "#"
      right_classes = "next btn pull-right disabled"
    end

    left = link_to "Previous Page", left_path, :class => left_classes
    right = link_to "Next Page", right_path, :class => right_classes

    left + right
  end

  def describe_import_status(import)
    descriptions = {
      "caching" => "Your file is being processed.",
      "pending" => "This import is pending your approval.",
      "approved" => "You have approved this import and it will be procesed soon.",
      "importing" => "Artful.ly is currently importing this file.",
      "imported" => "This import is complete.",
      "failed" => "This import has failed."
    }
    descriptions[import.status]
  end

end
