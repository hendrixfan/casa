class FileImporter
  require "csv"

  attr_reader :csv_filespec, :org_id, :number_imported, :failed_imports, :failed_volunteers

  def initialize(csv_filespec, org_id)
    @csv_filespec = csv_filespec
    @org_id = org_id
    @failed_imports = []
    @failed_volunteers = []
    @number_imported = 0
  end

  def import
    @number_imported = 0
    CSV.foreach(csv_filespec || [], headers: true, header_converters: :symbol) do |row|
      yield(row)
      @number_imported += 1
    rescue StandardError => e
      @failed_imports << row.to_hash.values.to_s
    end
  end

  private

  def result_hash(type)
    successful_import_message = "You successfully imported #{number_imported} #{type}"
    error_message = ' '
    if failed_volunteers.present?
      error_message << "The following volunteers were not imported:"
      error_message << failed_volunteers.map { |volunteer, supervisor, row_num|
        "#{volunteer.email} was not assigned to supervisor #{supervisor.email} on row ##{row_num}"
      }.join(", ")
    end
    if failed_imports.empty?
      {type: :success, message: "#{successful_import_message}."}
    else
      {type: :error, message: "#{successful_import_message}. "\
        "The following #{type} were not imported: #{failed_imports.join(", ")}.#{error_message}"}
    end

  end

  def gather_users(clazz, comma_separated_emails)
    comma_separated_emails.split(",")
      .map { |email| clazz.find_by(email: email.strip) }
      .compact
      .sort
  end
end
