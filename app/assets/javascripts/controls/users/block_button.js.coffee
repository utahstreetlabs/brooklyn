jQuery ->
  $block = $('#block')
  $blockLink = $.remoteLink.initRemoteLink($('a', $block))
  $blockLink.live 'jsend:success', (event, data) ->
    $block.html(data.block) if data.block?
    $blockLink = $block.find('a')
    $.remoteLink.initRemoteLink($blockLink)
    $($block.attr('data-follower-count')).html(data.followers) if data.followers?