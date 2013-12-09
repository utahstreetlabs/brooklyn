$(function() {
  $('#slides').slides({
    generatePagination: false,
    play: 7000,
    pause: 2500,
    hoverPause: true,
    animationStart: function(current){
      $('.caption').animate({
        bottom: -50
      },100);
    },
    animationComplete: function(current){
      $('.caption').animate({
        bottom: 0
      },200);
    },
    slidesLoaded: function(){
      $('.caption').animate({
        bottom: 0
      },200);
    }
  });
});