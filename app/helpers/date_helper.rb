module DateHelper
  def date(d)
    d.strftime('%B %e, %Y')
  end

  def datetime(dt)
    dt.strftime('%B %e, %Y at %l:%M %P')
  end
end
