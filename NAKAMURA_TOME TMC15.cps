/**
  Copyright (C) 2012-2020 by Autodesk, Inc.
  All rights reserved.

  FANUC Lathe post processor configuration.

  $Revision: 42798 a9dd4d215b6c53c3d39f9c6f220f2f4cb58ff4a0 $
  $Date: 2020-05-28 08:23:51 $
  
  FORKID {88B77760-269E-4d46-8588-30814E7FE9A1}
*/

description = "FANUC Turning";
vendor = "Fanuc";
vendorUrl = "http://www.fanuc.com";
legal = "Copyright (C) 2012-2020 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 40783;

longDescription = "Generic turning post for FANUC. Use the property 'type' to switch the FANUC mode A, B, and C. The default mode is A. Use Turret 0 for Positional Turret, Turret 101 for QCTP on X- Post, Turret 102 for QCTP on X+ Post, Turret 103 for Gang Tooling on X- Post, Turret 104 for Gang Tooling on X+ Tool Post.";

extension = "nc";
programNameIsInteger = true;
setCodePage("ascii");

capabilities = CAPABILITY_TURNING;
tolerance = spatial(0.002, MM);


minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowedCircularPlanes = undefined; // allow any circular motion


// user-defined properties
properties = {
  showSequenceNumbers: false, // show sequence numbers
  sequenceNumberStart: 10, // first sequence number
  sequenceNumberIncrement: 10, // increment for sequence numbers
  optionalStop: true, // optional stop
  maximumSpindleSpeed: 100 * 30, // specifies the maximum spindle speed
  HomePositionX: 100.0, // home position for X-axis
  HomePositionZ: 200.0, // home position for Z-axis
};

// user-defined property definitions
propertyDefinitions = {
  showSequenceNumbers: {title:"Use sequence numbers", description:"Use sequence numbers for each block of outputted code.", group:1, type:"boolean"},
  sequenceNumberStart: {title:"Start sequence number", description:"The number at which to start the sequence numbers.", group:1, type:"integer"},
  sequenceNumberIncrement: {title:"Sequence number increment", description:"The amount by which the sequence number is incremented by in each block.", group:1, type:"integer"},
  optionalStop: {title:"Optional stop", description:"Outputs optional stop code during when necessary in the code.", type:"boolean"},
  maximumSpindleSpeed: {title:"Max spindle speed", description:"Defines the maximum spindle speed allowed by your machines.", type:"integer", range:[0, 999999999]},
};

var separateWordsWithSpace = true;
var useSimpleThread = true;
var useRadius = false;
var CurrentSection = 0;
properties.type = "A";
//cycleExpanded = true;


var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-";

var gFormat = createFormat({prefix:"G", decimals:1});
var mFormat = createFormat({prefix:"M", decimals:1});

var spatialFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var xFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, scale:2}); // diameter mode
var yFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var zFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var rFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true}); // radius
var feedFormat = createFormat({decimals:(unit == MM ? 4 : 5), forceDecimal:true});
var pitchFormat = createFormat({decimals:6, forceDecimal:true});
var toolFormat = createFormat({decimals:0, width:2, zeropad:true});
var tooloffsetFormat = createFormat({decimals:0, width:2, zeropad:true});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-99999.999
var milliFormat = createFormat({decimals:0}); // milliseconds // range 1-9999
var taperFormat = createFormat({decimals:1, scale:DEG});
var threadP1Format = createFormat({decimals:0, forceDecimal:false, trim:false, width:6, zeropad:true});
var threadPQFormat = createFormat({decimals:0, forceDecimal:false, trim:true, scale:(unit == MM ? 1000 : 10000)});
var peckFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
// var peckFormat = createFormat({decimals:0, forceDecimal:false, trim:false, width:4, zeropad:true, scale:(unit == MM ? 1000 : 10000)});

var xOutput = createVariable({onchange: function() {retracted = false;}, prefix:"X"}, xFormat);
var yOutput = createVariable({prefix:"Y"}, yFormat);
var zOutput = createVariable({onchange: function() {retracted = false;}, prefix:"Z"}, zFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var pitchOutput = createVariable({prefix:"F", force:true}, pitchFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);

// circular output
var kOutput = createReferenceVariable({prefix:"K"}, spatialFormat);
var iOutput = createReferenceVariable({prefix:"I"}, spatialFormat); // no scaling
var threadP1Output = createVariable({prefix:"P", force:true}, threadP1Format);
var threadP2Output = createVariable({prefix:"P", force:true}, threadPQFormat);
var threadQOutput = createVariable({prefix:"Q", force:true}, threadPQFormat);
var threadROutput = createVariable({prefix:"R", force:true}, threadPQFormat);
var g92ROutput = createVariable({prefix:"R"}, zFormat); // no scaling
var peckOutput = createVariable({prefix:"Q", force:true}, peckFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91 // only for B and C mode
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G98-99 / G94-95
var gSpindleModeModal = createModal({}, gFormat); // modal group 5 // G96-97
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createModal({}, gFormat); // modal group 10 // G98-99

// fixed settings
var firstFeedParameter = 500;
var gotSecondarySpindle = true;
var gotTailStock = false;

var WARNING_WORK_OFFSET = 0;

var QCTP = 0;
var TURRET = 1;
var GANG = 2;

var FRONT = -1;
var REAR = 1;

// collected state
var sequenceNumber;
var currentWorkOffset;
var optionalSection = false;
var forceSpindleSpeed = false;
var activeMovements; // do not use by default
var currentFeedId;
var toolingData;
var previousToolingData;
var retracted = false; // specifies that the tool has been retracted to the safe plane // how does this apply to a lathe?

function getCode(code) {
  switch (code) {

  case "START_MAIN_SPINDLE_CW":
    return mFormat.format(3);
  case "START_MAIN_SPINDLE_CCW":
    return mFormat.format(4);
  case "FEED_MODE_UNIT_REV":
    return gFeedModeModal.format
  case "FEED_MODE_UNIT_MIN":
    return gFeedModeModal.format((properties.type == "A") ? 98 : 94);
  case "CONSTANT_SURFACE_SPEED_ON":
    return gSpindleModeModal.format(96);
  case "CONSTANT_SURFACE_SPEED_OFF":
    return gSpindleModeModal.format(97);
  case "COOLANT_FLOOD_ON":
    return mFormat.format(8);
  case "COOLANT_FLOOD_OFF":
    return mFormat.format(9);
  case "COOLANT_OFF":
    return mFormat.format(9);
  default:
    error(localize("Command " + code + " is not defined."));
    return 0;
  }
}

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  if (properties.showSequenceNumbers) {
    if (optionalSection) {
      if (text) {
        writeWords("/", "N" + sequenceNumber, text);
      }
    } else {
      writeWords2("N" + sequenceNumber, arguments);
    }
    sequenceNumber += properties.sequenceNumberIncrement;
  } else {
    if (optionalSection) {
      writeWords2("/", arguments);
    } else {
      writeWords(arguments);
    }
  }
}

/**
  Writes the specified optional block.
*/
function writeOptionalBlock() {
  if (properties.showSequenceNumbers) {
    var words = formatWords(arguments);
    if (words) {
      writeWords("/", "N" + sequenceNumber, words);
      sequenceNumber += properties.sequenceNumberIncrement;
    }
  } else {
    writeWords2("/", arguments);
  }
}

function formatComment(text) {
  return "(" + filterText(String(text).toUpperCase(), permittedCommentChars).replace(/[()]/g, "") + ")";
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function onOpen() 
{
  sequenceNumber = properties.sequenceNumberStart;
  writeln("%");

  if (programName) {
    var programId;
    try {
      programId = getAsInt(programName);
    } catch (e) {
      error(localize("Program name must be a number."));
      return;
    }
    if (properties.o8) {
      if (!((programId >= 1) && (programId <= 99999999))) {
        error(localize("Program number is out of range."));
        return;
      }
    } else {
      if (!((programId >= 1) && (programId <= 9999))) {
        error(localize("Program number is out of range."));
        return;
      }
    }
    var oFormat = createFormat({width:(properties.o8 ? 8 : 4), zeropad:true, decimals:0});
    if (programComment) {
      writeln("O" + oFormat.format(programId) + " (" + filterText(String(programComment).toUpperCase(), permittedCommentChars) + ")");
    } else {
      writeln("O" + oFormat.format(programId));
    }
  } else {
    error(localize("Program name has not been specified."));
    return;
  }
   writeBlock(gFormat.format(92), sOutput.format(properties.maximumSpindleSpeed));

}

function onComment(message) {
  writeComment(message);
}

/** Force output of X, Z. */
function forceXYZ() {
  xOutput.reset();
  zOutput.reset();
}

function forceFeed() {
  currentFeedId = undefined;
  feedOutput.reset();
}

/** Force output of X, Y, Z, and F on next output. */
function forceAny() {
  forceXYZ();
  forceFeed();
}

function FeedContext(id, description, feed) {
  this.id = id;
  this.description = description;
  this.feed = feed;
}

function getFeed(f) {
  if (activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return "F#" + (firstFeedParameter + feedContext.id);
      }
    }
    currentFeedId = undefined; // force Q feed next time
  }
  return feedOutput.format(f); // use feed value
}

function initializeActiveFeeds() {
  activeMovements = new Array();
  var movements = currentSection.getMovements();
  var feedPerRev = currentSection.feedMode == FEED_PER_REVOLUTION;
  
  var id = 0;
  var activeFeeds = new Array();
  if (hasParameter("operation:tool_feedCutting")) {
    if (movements & ((1 << MOVEMENT_CUTTING) | (1 << MOVEMENT_LINK_TRANSITION) | (1 << MOVEMENT_EXTENDED))) {
      var feedContext = new FeedContext(id, localize("Cutting"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_CUTTING] = feedContext;
      activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
      activeMovements[MOVEMENT_EXTENDED] = feedContext;
    }
    ++id;
    if (movements & (1 << MOVEMENT_PREDRILL)) {
      feedContext = new FeedContext(id, localize("Predrilling"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeMovements[MOVEMENT_PREDRILL] = feedContext;
      activeFeeds.push(feedContext);
    }
    ++id;
  }
  
  if (hasParameter("operation:finishFeedrate")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var finishFeedrateRel;
      if (hasParameter("operation:finishFeedrateRel")) {
        finishFeedrateRel = getParameter("operation:finishFeedrateRel");
      } else if (hasParameter("operation:finishFeedratePerRevolution")) {
        finishFeedrateRel = getParameter("operation:finishFeedratePerRevolution");
      }
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? finishFeedrateRel : getParameter("operation:finishFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  }
  
  if (hasParameter("operation:tool_feedEntry")) {
    if (movements & (1 << MOVEMENT_LEAD_IN)) {
      var feedContext = new FeedContext(id, localize("Entry"), feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_IN] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LEAD_OUT)) {
      var feedContext = new FeedContext(id, localize("Exit"), feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:noEngagementFeedrate")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), feedPerRev ? getParameter("operation:noEngagementFeedrateRel") : getParameter("operation:noEngagementFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting") &&
             hasParameter("operation:tool_feedEntry") &&
             hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(
        id,
        localize("Direct"),
        Math.max(
          feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"),
          feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"),
          feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit")
        )
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  }
  
  if (hasParameter("operation:reducedFeedrate")) {
    if (movements & (1 << MOVEMENT_REDUCED)) {
      var feedContext = new FeedContext(id, localize("Reduced"), feedPerRev ? getParameter("operation:reducedFeedrateRel") : getParameter("operation:reducedFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_REDUCED] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedRamp")) {
    if (movements & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_HELIX) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_ZIG_ZAG))) {
      var feedContext = new FeedContext(id, localize("Ramping"), feedPerRev ? getParameter("operation:tool_feedRampRel") : getParameter("operation:tool_feedRamp"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_RAMP] = feedContext;
      activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
      activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
      activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedPlunge")) {
    if (movements & (1 << MOVEMENT_PLUNGE)) {
      var feedContext = new FeedContext(id, localize("Plunge"), feedPerRev ? getParameter("operation:tool_feedPlungeRel") : getParameter("operation:tool_feedPlunge"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_PLUNGE] = feedContext;
    }
    ++id;
  }
  if (true) { // high feed
    if ((movements & (1 << MOVEMENT_HIGH_FEED)) || (highFeedMapping != HIGH_FEED_NO_MAPPING)) {
      var feed;
      if (hasParameter("operation:highFeedrateMode") && getParameter("operation:highFeedrateMode") != "disabled") {
        feed = getParameter("operation:highFeedrate");
      } else {
        feed = this.highFeedrate;
      }
      var feedContext = new FeedContext(id, localize("High Feed"), feed);
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
      activeMovements[MOVEMENT_RAPID] = feedContext;
    }
    ++id;
  }
  
  for (var i = 0; i < activeFeeds.length; ++i) {
    var feedContext = activeFeeds[i];
    writeBlock("#" + (firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed), formatComment(feedContext.description));
  }
}

function getSpindle() {
  if (getNumberOfSections() == 0) {
    return SPINDLE_PRIMARY;
  }
  if (getCurrentSectionId() < 0) {
    return getSection(getNumberOfSections() - 1).spindle == 0;
  }
  if (currentSection.getType() == TYPE_TURNING) {
    return currentSection.spindle;
  } else {
    if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
      return SPINDLE_PRIMARY;
    } else if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
      if (!gotSecondarySpindle) {
        error(localize("Secondary spindle is not available."));
      }
      return SPINDLE_SECONDARY;
    } else {
      return SPINDLE_PRIMARY;
    }
  }
}

function ToolingData(_tool) {
  switch (_tool.turret) {
  // Positional Turret
  case 0:
    this.tooling = TURRET;
    this.toolPost = REAR;
    break;
  // QCTP X-
  case 101:
    this.tooling = QCTP;
    this.toolPost = FRONT;
    break;
  // QCTP X+
  case 102:
    this.tooling = QCTP;
    this.toolPost = REAR;
    break;
  // Gang Tooling X-
  case 103:
    this.tooling = GANG;
    this.toolPost = FRONT;
    break;
  // Gang Tooling X+
  case 104:
    this.tooling = GANG;
    this.toolPost = REAR;
    break;
  default:
    error(localize("Turret number must be 0 (main turret), 101 (QCTP X-), 102 (QCTP X+, 103 (gang tooling X-), or 104 (gang tooling X+)."));
    break;
  }
  this.number = _tool.number;
  this.comment = _tool.comment;
  this.toolLength = _tool.bodyLength;
  // HSMWorks returns 0 in tool.bodyLength
  if ((tool.bodyLength == 0) && hasParameter("operation:tool_bodyLength")) {
    this.toolLength = getParameter("operation:tool_bodyLength");
  }
}

function onSection() 
{
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  var _spindlespeed;
  var spindleDir;
  var numberofsections = getNumberOfSections();
  var currentsection = getSection(CurrentSection);
  var Prevtool;
  var PrevSection;
  var Seqnumber;
  var comment = getParameter("operation-comment");

  if(!isFirstSection())
  {
    var Prevsection = getPreviousSection();
    var Prevtool = Prevsection.getTool().number;

    if(Prevsection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED)
    {
      var PrevSpindleSpeed = sOutput.format(Prevsection.getTool().surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0));
    }
    else  var PrevSpindleSpeed = sOutput.format(Prevsection.getTool().spindleRPM);
    var PrevSpindleMode = Prevsection.getTool().getSpindleMode();
    var PrevSpindleDir = Prevsection.getTool().clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW");

  }
  spindleDir = tool.clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW");

  if(properties.showSequenceNumbers)
  {
    Seqnumber = "";
  } else Seqnumber = "N" + tool.number; 

  if(tool.number != Prevtool)
  {
    if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) 
    {
      _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);

      if (comment)
      {
        writeComment(comment);
      }

      forceXYZ();
      writeBlock(Seqnumber, "G0", xOutput.format(properties.HomePositionX), zOutput.format(properties.HomePositionZ));
      writeBlock("G96", 
                 sOutput.format(_spindleSpeed),
                 spindleDir,
                 "T" + toolFormat.format(tool.number) + "00" );
    }
    else
    {
      if (comment)
      {
        writeComment(comment);
      }

      forceXYZ();
      writeBlock(Seqnumber, "G0", xOutput.format(properties.HomePositionX), zOutput.format(properties.HomePositionZ));
      writeBlock("G97", 
                 sOutput.format(tool.spindleRPM), 
                 spindleDir,
                "T" + toolFormat.format(tool.number) + "00" );
    }
  
    gMotionModal.reset();
  
    if(tool.coolant == COOLANT_FLOOD)
    {
      writeBlock( gMotionModal.format(0),
                  xOutput.format(initialPosition.x), 
                  zOutput.format(initialPosition.z),
                  "T" + toolFormat.format(tool.number) + tooloffsetFormat.format(tool.number),
                  "M8"); 
    }
    else if(tool.coolant == COOLANT_OFF)
    {
      writeBlock( gMotionModal.format(0), 
                  xOutput.format(initialPosition.x), 
                  zOutput.format(initialPosition.z),
                  "T" + toolFormat.format(tool.number) + tooloffsetFormat.format(tool.number),
                  "M9");
    }
  }
  else
  {
    if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) 
    {
      _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
    }
    else _spindleSpeed = tool.spindleRPM;

    if((PrevSpindleSpeed != sOutput.format(_spindleSpeed)) || (PrevSpindleMode != tool.getSpindleMode()) || (PrevSpindleDir != spindleDir ))
    {
      if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) 
      {
        if (comment)
        {
          writeComment(comment);
        }

        _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
        writeBlock("G96", 
                   sOutput.format(_spindleSpeed),
                   spindleDir);
      }
      else
      {
        if (comment)
        {
          writeComment(comment);
        }
        
        writeBlock("G97", 
                   sOutput.format(tool.spindleRPM), 
                   spindleDir);
      }
    }
    gMotionModal.reset();
    forceXYZ();
    writeBlock( gMotionModal.format(0),
                xOutput.format(initialPosition.x), 
                zOutput.format(initialPosition.z));
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  milliseconds = clamp(1, seconds * 1000, 99999999);
  writeBlock(/*gFeedModeModal.format(94),*/ gFormat.format(4), "P" + milliFormat.format(milliseconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(0), gFormat.format(41), x, z);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(0), gFormat.format(42), x, z);
        break;
      default:
        writeBlock(gMotionModal.format(0), gFormat.format(40), x, z);
      }
    } else {
      writeBlock(gMotionModal.format(0), x, z);
    }
    forceFeed();
  }
}

var resetFeed = false;

function onLinear(_x, _y, _z, feed) {
  if (isSpeedFeedSynchronizationActive()) {
    resetFeed = true;
    var threadPitch = getParameter("operation:threadPitch");
    var threadsPerInch = 1.0 / threadPitch; // per mm for metric
    writeBlock(gMotionModal.format(33), xOutput.format(_x), yOutput.format(_y), zOutput.format(_z), pitchOutput.format(1 / threadsPerInch));
    return;
  }
  if (resetFeed) {
    resetFeed = false;
    forceFeed();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = getFeed(feed);
  if (x || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      writeBlock(gPlaneModal.format(18));
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(41), x, z, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(42), x, z, f);
        break;
      default:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(40), x, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), x, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), f);
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) 
{
  var start = getCurrentPosition();
  var directionCode = (1) ? (clockwise ? 2 : 3) : (clockwise ? 3 : 2);

  writeBlock(conditional(gAbsIncModal.format(90)), gMotionModal.format(directionCode), xOutput.format(x), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
}

function onCycle() {
}

var saveShowSequenceNumbers = true;
var xyzFormat = createFormat({decimals:(unit == MM ? 4 : 5), forceDecimal:true});
var pathBlockNumber = {start: 0, end: 0};

function onCyclePath() {
  saveShowSequenceNumbers = properties.showSequenceNumbers;

  // buffer all paths and stop feeds being output
  feedOutput.disable();
  properties.showSequenceNumbers = false;
  redirectToBuffer();
  gMotionModal.reset();
  if ((hasParameter("operation:grooving") && getParameter("operation:grooving").toUpperCase() != "OFF")) {
    forceXYZ();
  }
}

function onCyclePathEnd() {
  properties.showSequenceNumbers = saveShowSequenceNumbers; // reset property to initial state
  feedOutput.enable();
  var cyclePath = String(getRedirectionBuffer()).split(EOL); // get cycle path from buffer
  closeRedirection();
  for (line in cyclePath) { // remove empty elements
    if (cyclePath[line] == "") {
      cyclePath.splice(line);
    }
  }

  var verticalPasses;
  if (cycle.profileRoughingCycle == 0) {
    verticalPasses = false;
  } else if (cycle.profileRoughingCycle == 1) {
    verticalPasses = true;
  } else {
    error(localize("Unsupported passes type."));
    return;
  }
  // output cycle data
  switch (cycleType) {
  case "turning-canned-rough":
    writeBlock(gFormat.format(verticalPasses ? 72 : 71),
      (verticalPasses ? "W" : "U") + xyzFormat.format(cycle.depthOfCut),
      "R" + xyzFormat.format(cycle.retractLength)
    );
    writeBlock(gFormat.format(verticalPasses ? 72 : 71),
      "P" + (getStartEndSequenceNumber(cyclePath, true)),
      "Q" + (getStartEndSequenceNumber(cyclePath, false)),
      "U" + xFormat.format(cycle.xStockToLeave),
      "W" + xyzFormat.format(cycle.zStockToLeave),
      getFeed(cycle.cutfeedrate)
    );
    break;
  default:
    error(localize("Unsupported turning canned cycle."));
  }
  
  for (var i = 0; i < cyclePath.length; ++i) {
    if (i == 0 || i == (cyclePath.length - 1)) { // write sequence number on first and last line of the cycle path
      properties.showSequenceNumbers = true;
      if ((i == 0 && pathBlockNumber.start != sequenceNumber) || (i == (cyclePath.length - 1) && pathBlockNumber.end != sequenceNumber)) {
        error(localize("Mismatch of start/end block number in turning canned cycle."));
        return;
      }
    }
    writeBlock(cyclePath[i]); // output cycle path
    properties.showSequenceNumbers = saveShowSequenceNumbers; // reset property to initial state
  }
}

function getStartEndSequenceNumber(cyclePath, start) {
  if (start) {
    pathBlockNumber.start = sequenceNumber + conditional(saveShowSequenceNumbers, properties.sequenceNumberIncrement);
    return pathBlockNumber.start;
  } else {
    pathBlockNumber.end = sequenceNumber + properties.sequenceNumberIncrement + conditional(saveShowSequenceNumbers, (cyclePath.length - 1) * properties.sequenceNumberIncrement);
    return pathBlockNumber.end;
  }
}

function getCommonCycle(x, y, z, r) {
  forceXYZ(); // force xyz on first drill hole of any cycle
  return [xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + spatialFormat.format(r)];
}

var threadStart;
var threadEnd;
function moveToThreadStart(x, y, z) 
{
  var cuttingAngle = 30;
  if (hasParameter("operation:infeedAngle")) 
  {
    cuttingAngle = getParameter("operation:infeedAngle");
  }
  if (cuttingAngle != 0) 
  {
    var zz;
    if (isFirstCyclePoint()) 
    {
      threadStart = getCurrentPosition();
      threadEnd = new Vector(x, y, z);
    } else 
    {
      var zz = threadStart.z - (Math.abs(threadEnd.x - x) * Math.tan(toRad(cuttingAngle)));
      writeBlock(gMotionModal.format(0), zOutput.format(zz));
      xOutput.reset();
      zOutput.reset();
      g92ROutput.reset();
      feedOutput.reset();
      threadStart.setZ(zz);
      threadEnd = new Vector(x, y, z);
    }
  }
}

function onCyclePoint(x, y, z)
 {
  if(cycleType == "thread-turning" )
  {
    var inverted = (1) ? 1 : -1;
    var r = -cycle.incrementalX * inverted; // positive if taper goes down - delta radius
    moveToThreadStart(x, y, z);
    var threadsPerInch = 1.0 / cycle.pitch; // per mm for metric
    var f = 1 / threadsPerInch;
    var codes = {A: 33, B: 78, C: 21};
    writeBlock(gMotionModal.format(0),xOutput.format(x - cycle.incrementalX));
    writeBlock(gMotionModal.format(codes[properties.type]),zOutput.format(z), feedOutput.format(f));
    writeBlock(gMotionModal.format(0),xOutput.format(threadStart.x));
  } 
  else 
  {
    cycle.feedrate = cycle.feedrate/spindleSpeed;
    expandCyclePoint(x, y, z);
  }
}

function onCycleEnd() {
  if (!cycleExpanded) {
    switch (cycleType) {
    case "thread-turning":
      forceFeed();
      xOutput.reset();
      zOutput.reset();
      g92ROutput.reset();
      break;
    default:
    //  writeBlock(gCycleModal.format(80));
    }
  }
}

var currentCoolantMode = COOLANT_OFF;

function setCoolant(coolant) {
  if (coolant == currentCoolantMode) {
    return; // coolant is already active
  }

  var m = undefined;
  if (coolant == COOLANT_OFF) {
    writeBlock((currentCoolantMode == COOLANT_THROUGH_TOOL) ? getCode("COOLANT_THROUGH_TOOL_OFF") : getCode("COOLANT_OFF"));
    currentCoolantMode = COOLANT_OFF;
    return;
  }

  switch (coolant) {
  case COOLANT_FLOOD:
    m = getCode("COOLANT_FLOOD_ON");
    break;
  case COOLANT_THROUGH_TOOL:
    m = getCode("COOLANT_THROUGH_TOOL_ON");
    break;
  default:
    onUnsupportedCoolant(coolant);
    m = getCode("COOLANT_OFF");
  }
  
  if (m) {
    writeBlock(m);
    currentCoolantMode = coolant;
  }
}

function onSpindleSpeed(spindleSpeed) {
  if (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) {
    writeBlock(sOutput.format(spindleSpeed));
  }
}

function startSpindle(tappingMode, forceRPMMode, initialPosition) {
  var spindleDir;
  var _spindleSpeed;
  var spindleMode;
  var maxSpeed = "";
  gSpindleModeModal.reset();
  gSpindleModeModal.reset();

  if ((getSpindle() == SPINDLE_SECONDARY) && !gotSecondarySpindle) {
    error(localize("Secondary spindle is not available."));
    return;
  }
 
  if (tappingMode) {
    writeBlock(mFormat.format(29), sOutput.format(spindleSpeed));
    return;
  } else {
    if (getSpindle() == SPINDLE_SECONDARY) {
      spindleDir = tool.clockwise ? getCode("START_SUB_SPINDLE_CW") : getCode("START_SUB_SPINDLE_CCW");
    } else {
      spindleDir = tool.clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW");
    }
  }

  var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, properties.maximumSpindleSpeed) : properties.maximumSpindleSpeed;
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
    if (forceRPMMode) { // RPM mode is forced until move to initial position
      if (xFormat.getResultingValue(initialPosition.x) == 0) {
        _spindleSpeed = maximumSpindleSpeed;
      } else {
        _spindleSpeed = Math.min((_spindleSpeed * ((unit == MM) ? 1000.0 : 12.0) / (Math.PI * Math.abs(initialPosition.x * 2))), maximumSpindleSpeed);
      }
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF");
    } else {
      if (properties.type == "A") {
        writeBlock(gFormat.format(92), sOutput.format(maximumSpindleSpeed));
      } else {
        writeBlock(gFormat.format(92), sOutput.format(maximumSpindleSpeed));
      }
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_ON");
    }
  } else {
    _spindleSpeed = spindleSpeed;
    spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF");
  }
  if (getSpindle(true) == SPINDLE_SECONDARY) {
    writeBlock(
      spindleMode,
      sOutput.format(_spindleSpeed),
      spindleDir
    );
  } else {
    writeBlock(
      spindleMode,
      sOutput.format(_spindleSpeed),
      spindleDir
    );
  }
  // wait for spindle here if required
}

function onCommand(command) {
  switch (command) {
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    return;
  case COMMAND_COOLANT_ON:
    setCoolant(COOLANT_FLOOD);
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    return;
  case COMMAND_START_CHIP_TRANSPORT:
    // getCode("START_CHIP_TRANSPORT");
    return;
  case COMMAND_STOP_CHIP_TRANSPORT:
    // getCode("STOP_CHIP_TRANSPORT");
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  case COMMAND_ACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    return;
  case COMMAND_DEACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    return;
  case COMMAND_STOP:
    writeBlock(mFormat.format(0));
    forceSpindleSpeed = true;
    return;
  case COMMAND_OPTIONAL_STOP:
    writeBlock(mFormat.format(1));
    break;
  case COMMAND_END:
    writeBlock(mFormat.format(2));
    break;
  case COMMAND_SPINDLE_CLOCKWISE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(3));
      break;
    case SPINDLE_SECONDARY:
      writeBlock(mFormat.format(143));
      break;
    }
    break;
  case COMMAND_SPINDLE_COUNTERCLOCKWISE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(4));
      break;
    case SPINDLE_SECONDARY:
      writeBlock(mFormat.format(144));
      break;
    }
    break;
  case COMMAND_START_SPINDLE:
    onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
    return;
  case COMMAND_STOP_SPINDLE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(5));
      break;
    case SPINDLE_SECONDARY:
      writeBlock(mFormat.format(145));
      break;
    }
    break;
  case COMMAND_ORIENTATE_SPINDLE:
    if (getSpindle() == 0) {
      writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
    } else {
      writeBlock(mFormat.format(119));
    }
    break;
  //case COMMAND_CLAMP: // TAG: add support for clamping
  //case COMMAND_UNCLAMP: // TAG: add support for clamping
  default:
    onUnsupportedCommand(command);
  }
}

function onSectionEnd()
 {
  var _xHome;
  var _zHome;
  var _ToolCancel;
  var numberofsections = getNumberOfSections();
  var currentsection = getSection(CurrentSection);
  var tool = currentsection.getTool();

  if(CurrentSection < (numberofsections - 1))
  {
    var nextsection = getSection(CurrentSection + 1);
    var nexttool = nextsection.getTool();

    if (tool.number != nexttool.number)
    {
      _xHome = xOutput.format(properties.HomePositionX);
      _zHome = zOutput.format(properties.HomePositionZ);
      _ToolCancel = "T" + toolFormat.format(tool.number) + "00";
      writeBlock(gMotionModal.format(0), _xHome, _zHome, _ToolCancel);
      if(properties.optionalStop)
      {
        writeBlock("M1");
      }
    }
  }
  else if(CurrentSection = (numberofsections - 1))
  {
    _xHome = xOutput.format(properties.HomePositionX);
    _zHome = zOutput.format(properties.HomePositionZ);
    _ToolCancel = "T" + toolFormat.format(tool.number) + "00";
    writeBlock(gMotionModal.format(0), _xHome, _zHome, _ToolCancel);
  }
  CurrentSection = CurrentSection + 1;
}

/** Output block to do safe retract and/or move to home position. */

function writeRetract() 
{


}

function onClose() 
{
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
  writeln("%");
}
