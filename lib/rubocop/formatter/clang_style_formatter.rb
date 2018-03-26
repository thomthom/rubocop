# frozen_string_literal: true

module RuboCop
  module Formatter
    # This formatter formats report data in clang style.
    # The precise location of the problem is shown together with the
    # relevant source code.
    class ClangStyleFormatter < SimpleTextFormatter
      ELLIPSES = '...'.freeze

      def report_file(file, offenses)
        offenses.each { |offense| report_offense(file, offense) }
      end

      private

      def report_offense(file, offense)
        output.printf("%s:%d:%d: %s: %s\n",
                      cyan(smart_path(file)), offense.line, offense.real_column,
                      colored_severity_code(offense), message(offense))

        # rubocop:disable Lint/HandleExceptions
        begin
          return unless valid_line?(offense)

          report_line(offense.location)
          # report_highlighted_area(offense.highlighted_area)
          report_highlighted_area(offense)
        rescue IndexError
          # range is not on a valid line; perhaps the source file is empty
        end
        # rubocop:enable Lint/HandleExceptions
      end

      def valid_line?(offense)
        !offense.location.source_line.blank?
      end

      def report_line(location)
        source_line = format_tabs(location.source_line)

        if location.first_line == location.last_line
          output.puts(source_line)
        else
          output.puts("#{source_line} #{yellow(ELLIPSES)}")
        end
      end

      def report_highlighted_area(offense)
        # highlighted_area.source_line threw errors because Range it returned
        # had a String for buffer instead of a Bugger object.
        highlighted_area = offense.highlighted_area
        source_line = offense.location.source_line

        # Compute additional tab-offset for the source before the highlight.
        head_source = source_line[0...highlighted_area.begin_pos]
        content_start = tab_offset(head_source) + highlighted_area.begin_pos

        # Compute additional tab-offset for the highlighted source.
        content_source = highlighted_area.source
        content_size = tab_offset(content_source) + highlighted_area.size

        output.puts("#{' ' * content_start}" \
                    "#{'^' * content_size}")
      end

      TAB_SIZE = 2
      FORMATTED_TAB = ' ' * TAB_SIZE

      def format_tabs(string)
        string.gsub("\t", FORMATTED_TAB)
      end

      def tab_offset(string)
        tabs = string.count("\t")
        (tabs * TAB_SIZE) - tabs
      end
    end
  end
end
