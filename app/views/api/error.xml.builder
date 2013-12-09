xml.instruct!

xml.error do
  xml.message error_message if error_message
  if invalid_fields
    xml.invalid_fields do
      invalid_fields.each do |attr,msg|
        xml.send(attr, msg)
      end
    end
  end
end
