// avoid warnings from early browsers
if (typeof console === "undefined") {
  console = { log: function() {} };
}

var SPEED_UP_TIME = false;
var startingTime = new Date();
function getCurrentDate() {
  if (SPEED_UP_TIME) {
    var difference = new Date().getTime() - startingTime.getTime();
    return new Date(startingTime.getTime() + (difference * 100));
  } else {
    return new Date();
  }
}
var WAIT_MINUTE_BETWEEN_UPDATES = (SPEED_UP_TIME) ? 1000 : (60 * 1000)

var BLUR_INTENTION_TIMEOUT_MILLIS = 6000;
var AJAX_TIMEOUT_MILLIS = 4000;
var OVER_TIME_FLASH_RATE_MILLIS = 1000;
var DEFAULT_INTENDED_DURATION_MINS = (SPEED_UP_TIME) ? 300 : 30;

var previousActivity = null;
var currentActivity = {
  startDate: getCurrentDate(),
  finishDate: null
};

function twoDigits(i) {
  var s = i.toString();
  return (s.length == 1) ? ("0" + s) : s;
};

function formatTimestamp(date) {
  var out = '';
  out += (1900 + date.getYear()) + '-';
  out += twoDigits(date.getMonth() + 1) + '-';
  out += twoDigits(date.getDate()) + " ";
  out += twoDigits(date.getHours()) + ":";
  out += twoDigits(date.getMinutes()) + ":";
  out += twoDigits(date.getSeconds());
  return out;
}

function log(line) {
  if (typeof(console) != 'undefined') {
    console.log(line);
  }
}

var ajaxTimeout = null;

function ajaxError() {
  document.getElementById('message').innerHTML = 'AJAX Error';
}

function postPreviousActivity(activity) {
  activity.startDateString = formatTimestamp(activity.startDate);
  activity.finishDateString = formatTimestamp(activity.finishDate);
  activity.startDateSeconds = activity.startDate.getTime();
  activity.finishDateSeconds = activity.finishDate.getTime();
  log(activity);

  ajaxTimeout = window.setTimeout(ajaxError, AJAX_TIMEOUT_MILLIS);
  request = new XMLHttpRequest();
  request.onerror = ajaxError;
  request.open("POST", "/append-log", true); // 3rd param means async=true
  request.onreadystatechange = function() {
    if (request.readyState == 4 && request.status == 200) {
      window.clearTimeout(ajaxTimeout);
    }
  };
  request.send(JSON.stringify(activity));
}

var minuteUpdateInterval = null;

function changeActivity(numMinutesAgo) {
  var oldIntention = document.getElementById('intention').value;
  var oldIntendedDuration = document.getElementById('intended-duration').value;

  snoozeFlashing();

  document.getElementById('intention').value = '';
  document.getElementById('intended-duration').value =
    DEFAULT_INTENDED_DURATION_MINS;

  var now = getCurrentDate();
  if (currentActivity) {
    previousActivity = currentActivity;
    currentActivity = null;

    var finishDate = (numMinutesAgo > 0) ?
      new Date(previousActivity.startDate.getTime() +
        (numMinutesAgo * 60 * 1000)) : now;
    previousActivity.finishDate = finishDate
    previousActivity.intention = oldIntention;
    previousActivity.intendedDuration = oldIntendedDuration;

    postPreviousActivity(previousActivity);
  }

  currentActivity = {
    startDate: previousActivity ? previousActivity.finishDate : now,
    finishDate: null,
  };

  if (minuteUpdateInterval) {
    window.clearInterval(minuteUpdateInterval);
  }
  minuteUpdateInterval =
    window.setInterval(updateDurationSoFar, WAIT_MINUTE_BETWEEN_UPDATES);
  updateDurationSoFar();
}

function flashForOverTime() {
  var wash = document.getElementById('color-wash');
  if (wash.style.backgroundColor == 'black') {
    wash.style.backgroundColor = 'gray';
  } else {
    wash.style.backgroundColor = 'black';
  }
}

var overTimeInterval = null;
function snoozeFlashing() {
  if (overTimeInterval) {
    window.clearInterval(overTimeInterval);
  }
  overTimeInterval = null;
  var wash = document.getElementById('color-wash');
}

function updateDurationSoFar() {
  if (!currentActivity) return;
  var numMillis =
    getCurrentDate().getTime() - currentActivity.startDate.getTime();
  var numMinutes = Math.floor(numMillis / (60 * 1000));
  document.getElementById('duration-so-far').innerHTML = numMinutes;

  var numIntendedMinutes =
    parseInt(document.getElementById('intended-duration').value);

  if (numIntendedMinutes > 0 &&
      numMinutes > numIntendedMinutes) {
    if (!overTimeInterval) {
      document.addEventListener('mousemove', snoozeFlashing, false);
      overTimeInterval = window.setInterval(flashForOverTime,
        OVER_TIME_FLASH_RATE_MILLIS);
    }
  }
}

var blurIntentionTimeout = null;
function blurIntention() {
  // so next time Tab is pressed, it goes to intention
  document.getElementById('unfocus').focus();
}

var ESCAPE_KEY = 27;
var BACKSPACE_KEY = 8;
var DELETE_KEY = 46;
function handleKeydownInIntentionFields(e) {
  if (e.keyCode === ESCAPE_KEY) {
    blurIntention();
    return;
  }

  if (e.keyCode !== BACKSPACE_KEY && e.keyCode !== DELETE_KEY) {
    window.setTimeout(tryAutoComplete, 1);
  }

  // reset blur intention timeout
  if (blurIntentionTimeout) {
    window.clearTimeout(blurIntentionTimeout);
  }
  blurIntentionTimeout =
    window.setTimeout(blurIntention, BLUR_INTENTION_TIMEOUT_MILLIS);

  // don't let numbers entered switch the activity
  e.stopPropagation();

  return true;
}

function tryAutoComplete(e) {
  var text = document.getElementById('intention').value;

  var minLength = 99999;
  var bestAutoCompletion = null;
  if (text !== "") {
    for (var i = 0; i < auto_completions.length; i++) {
      var autoCompletion = auto_completions[i];
      if (autoCompletion.indexOf(text) == 0 &&
          autoCompletion.length < minLength) {
        minLength = autoCompletion.length;
        bestAutoCompletion = autoCompletion;
      }
    }
  }

  if (bestAutoCompletion !== null) {
    var subtracted = bestAutoCompletion.substr(text.length);
    var box = document.getElementById('intention');
    var originalLength = box.value.length;
    box.value += subtracted;
    box.selectionStart = originalLength;
    box.selectionEnd = box.value.length;
  }
}

function showIntentionFocus() {
  document.getElementById('intention').style.backgroundColor = 'white';
  document.getElementById('intention').style.color = 'black';
}

function showIntentionBlur() {
  document.getElementById('intention').style.backgroundColor = 'transparent';
  document.getElementById('intention').style.color = 'white';
}

function showIntendedDurationFocus() {
  document.getElementById('intended-duration').style.backgroundColor = 'white';
  document.getElementById('intended-duration').style.color = 'black';
}

function showIntendedDurationBlur() {
  document.getElementById('intended-duration').style.backgroundColor =
    'transparent';
  document.getElementById('intended-duration').style.color =
    'white';
}

var DIGIT_0 =  48;
var DIGIT_9 =  57;
var ENTER   =  13;
var HYPHEN1 = 189;
var HYPHEN2 = 109;
function handleDocumentKeydown(e) {
  if (e.keyCode == ENTER) {
    changeActivity(0);
    e.preventDefault();
    return false;
  } else if (e.keyCode == HYPHEN1 || e.keyCode == HYPHEN2) {
    var numMinutesAgo =
      window.prompt('How many minutes to confirm for this activity?');
    if (numMinutesAgo === parseInt(numMinutesAgo).toString()) {
      changeActivity(numMinutesAgo);
    }
    e.preventDefault();
    return false;
  } else {
    return true;
  }
}

function onloadcalled() {
  document.addEventListener('keydown', handleDocumentKeydown, false);
  document.getElementById('intention').addEventListener(
    'focus', showIntentionFocus, false);
  document.getElementById('intention').addEventListener(
    'blur', showIntentionBlur, false);
  document.getElementById('intended-duration').addEventListener(
    'focus', showIntendedDurationFocus, false);
  document.getElementById('intended-duration').addEventListener(
    'blur', showIntendedDurationBlur, false);
  document.getElementById('intention').addEventListener(
    'focus', handleKeydownInIntentionFields, false);
  document.getElementById('intention').addEventListener(
    'keydown', handleKeydownInIntentionFields, false);
  document.getElementById('intended-duration').addEventListener(
    'focus', handleKeydownInIntentionFields, false);
  document.getElementById('intended-duration').addEventListener(
    'keydown', handleKeydownInIntentionFields, false);

  blurIntention(); // so tab key works consistently
}

window.onload = onloadcalled;
