def distort_markdown
  Proc.new { |document, payload|
    # Compare any given document's file extension to the list of enabled
    # Markdown file extensions in Jekyll's config.
    if payload['site']['markdown_ext'].include? document.extname.downcase[1..-1]
      # Convert Markdown images to {% distorted %} tags.
      # https://kramdown.gettalong.org/syntax.html#images
      #
      # ![alt text](cool.jpg 'title text'){:other="options"}
      document.content = document.content.gsub(
        /!\[(?<alt>.*)\]\((?<name>[^'")]+)(['"](?<title>[^'")]+)['"])?\)(?:{:([^}]+)})*/,
        '{% distorted \k<name> alt="\k<alt>" title="\k<title>" %}'
      )
    end
  }
end
