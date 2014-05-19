////////////////////////////////
// Phone Slideshow           //
//////////////////////////////
if (typeof jQuery !== "undefined") {
  $(function() {
    $('.phoneframe img:gt(0)').hide();
      setInterval(function() {
        $('.phoneframe :first-child').fadeOut().next('img').fadeIn().end().appendTo('.phoneframe');
      }, 3000);
  });
}
//////////////
// Mobile  //
////////////
var is_mobile = false;
if( /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
  is_mobile = true;
}
//////////////
// Local   //
////////////
if (window.location.origin.indexOf("8888") !== -1)
{
  handleError("development mode");
}
///////////////////////////////////////
//  ERRORS                          //
/////////////////////////////////////
function handleError(msg) {
  document.getElementById('general-error-wrapper').style.display="block";
  document.getElementById('general-error').innerHTML = msg;
  setTimeout(function() {document.getElementById('general-error-wrapper').style.display="none";},2500);
}

///////////////////////////////////////
//  IMAGES                          //
/////////////////////////////////////
/*
function expandImage(img)
{
  var image = img;
  if(image){
    addImage(image);
  }
}
function addImage(full)
{
  $('#fullscreen_image').html('<img alt="flier" width="95%" style="margin: 10px 0 10px 0;"  src=' + full + ' />');
  $('#fullscreen_image').show();
  $('#fullscreen_image').parent().show();
}

///////////////////////////////////////
//  TEXT                            //
/////////////////////////////////////
function truncate(str)
{
  if (str.length > 200){
    var pos = 180,
    // Search for the word's beginning and end.
    right = str.slice(pos).search(/\s/);
    return str.substring(0, pos + right)+'<span class="link read-less" style="display:none;">less</span><span style="display:inline;"class="link read-more">... more</span>';
  } else {
    return str;
  }
}
///////////////////////////////////////
//  FORMS                           //
/////////////////////////////////////
function form_as_object(form)
{
  var object = {};
  var split = (form.serialize()).split('&');
  for (var i in split)
  {
    var key_value = split[i].split('=');
    object[key_value[0]] = key_value[1];
  }
  return object;
}
///////////////////////////////////////
//  COUNTDOWN                       //
/////////////////////////////////////
function countdown(deadline, id)
{
  // set the date we're counting down to
  var target_date = new Date(deadline).getTime();
  calculateCountdown(target_date, id);
   
  // update the tag with id "countdown" every 1 second
  setInterval(function () {
    calculateCountdown(target_date, id);
  }, 1000 * 60);
}
function calculateCountdown(target_date, id) {
  // variables for time units
  var days, hours, minutes, seconds;
  
  // find the amount of "seconds" between now and target
  var current_date = new Date().getTime();
  var seconds_left = (target_date - current_date) / 1000;

  // do some time calculations
  days = padInt(parseInt(seconds_left / 86400));
  seconds_left = seconds_left % 86400;

  hours = padInt(parseInt(seconds_left / 3600));
  seconds_left = seconds_left % 3600;

  minutes = padInt(parseInt(seconds_left / 60));
  seconds = padInt(parseInt(seconds_left % 60));

  // format countdown string + set tag value
  $('#countdown-days-'+id).html(days);
  $('#countdown-hours-'+id).html(hours);
  $('#countdown-minutes-'+id).html(minutes);
}
function padInt(n) {
  return (n < 10) ? ("0" + n) : n;
}
///////////////////////////////////////
//  Horizontal Pan Arrows           //
/////////////////////////////////////
function panArrows()
{
  var scrollHandle = 0,
      scrollStep = 5,
      parent = $(".scrolls");
  //Start the scrolling process
  $(".panner").on("mouseenter", function () {
    var data = $(this).data('scrollModifier'), direction = parseInt(data, 10);
    $(this).addClass('active');
    startScrolling(direction, scrollStep);
  });
  //Kill the scrolling
  $(".panner").on("mouseleave", function () {
    stopScrolling();
    $(this).removeClass('active');
  });
  //Actual handling of the scrolling
  function startScrolling(modifier, step) {
    if (scrollHandle === 0) {
      scrollHandle = setInterval(function () {
        var newOffset = parent.scrollLeft() + (scrollStep * modifier);
        parent.scrollLeft(newOffset);
      }, 10);
    }
  }
  function stopScrolling() {
    clearInterval(scrollHandle);
    scrollHandle = 0;
  }
}
*/
// If Jquery isn't loaded load it
// window.jQuery || document.write('<script src="js/libs/jquery-2.0.0.min.js">\x3C/script>');

// usage: log('inside coolFunc', this, arguments);
// paulirish.com/2009/log-a-lightweight-wrapper-for-consolelog/

window.log = function f() {
    log.history = log.history || [];
    log.history.push(arguments);
    if (this.console) {
        var args = arguments;
        var newarr;

        try {
            args.callee = f.caller;
        } catch(e) {

        }

        newarr = [].slice.call(args);

        if (typeof console.log === 'object') {
            log.apply.call(console.log, console, newarr);
        } else {
            console.log.apply(console, newarr);
        }
    }
};

// make it safe to use console.log always

(function(a) {
    function b() {}
    var c = "assert,count,debug,dir,dirxml,error,exception,group,groupCollapsed,groupEnd,info,log,markTimeline,profile,profileEnd,time,timeEnd,trace,warn";
    var d;
    for (c = c.split(","); !!(d = c.pop());) {
        a[d] = a[d] || b;
    }
})(function() {
    try {
        console.log();
        return window.console;
    } catch(a) {
        return (window.console = {});
    }
}());
