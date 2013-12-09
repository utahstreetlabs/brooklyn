class ClosedStruct
  def fields
    @table.keys.map{|k| k.to_s}
  end
end
