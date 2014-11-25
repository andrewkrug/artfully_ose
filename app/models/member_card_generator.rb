# Generates a PDF of member cards.
#
# Generators use a namespace and classes to take advantage of the convention
# used to include templates in PdfGeneration (ClassName -> partial_name in app/views/pdfs).
#
# Supported Member Card Templates:
#   * Blanks Usa Id Card 6 (6 cards per 8"x11" page)
#
# To add support for other Member Card templates:
#   1. Create a class in the MemberCardGenerator namespace and include InstanceMethods
#   2. Create a partial in app/views/pdfs/member_card_generator using underscored version of the class name (e.g. Avery5361LaminatedIdCards -> avery5361_laminated_id_cards)
#
# Examples:
#
#    generator    = MemberCardGenerator::BlanksUsaIdc6.new(members)
#    download_url = generator.generate
module MemberCardGenerator
  module InstanceMethods
    attr_reader :download_url
    attr_reader :members

    def initialize(members, template='blanks_usa_idc6')
      @members = Array.wrap(members)
      validate_members!
    end

    def id
      hash
    end

    def generate
      @download_url = pdf_generator.generate
    end

    def members
      @members.select { |m| !m.memberships.current.first.blank? }
    end

    def pdf_generator
      @pdf_generator ||= begin
        PdfGeneration.new(self).tap do |p|
          p.pdf_options = {
            :page_size => 'Letter'
          }
        end
      end
    end

    def validate_members!
      errors = []

      members.each_with_index do |member,index|
        errors << "    #{member.class} found at position #{index}" unless member.kind_of?(Member)
      end

      raise ArgumentError, "Only Member objects are supported for generating member cards:\n" + errors.join("\n") unless errors.empty?
    end
  end

  class BlanksUsaIdc6
    include InstanceMethods
  end
end
