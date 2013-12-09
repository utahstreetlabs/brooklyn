module BalancedHelper
  def link_to_balanced(url)
    text = url.sub(%r{.+/}, '')
    url = url.sub(%r{/v1}, 'http://balancedpayments.com')
    link_to(text, url, target: 'balanced')
  end
end
