module MainHelper
  def standardize_header(header)
    header.parameterize.downcase.underscore
  end
end
