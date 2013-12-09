jQuery ->
  if Modernizr.mq("only screen and (max-device-width: 480px)")
     document.getElementById("viewport").setAttribute("content","width=device-width, initial-scale=1")
     window.scrollTo(0, 1)
