//**********************************************************************
// DESCRIPTION : Watch Faces for Trio
// AUTHORS :
//          Created by ivalkou - https://github.com/ivalkou
//          Modify by Pierre Lagarde - https://github.com/avouspierre
// COPYRIGHT : (c) 2023 ivalkou / Lagarde
//

import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.Time.Gregorian as Calendar;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Time;
import Sura.Device;
import Sura.Datetime;

class TrioWatchfaceView extends WatchUi.WatchFace {
    var timeFontSize as Graphics.FontDefinition = Graphics.FONT_NUMBER_MEDIUM;
    var smallFont = Graphics.FONT_XTINY;
    var smallFontSize = Graphics.getFontHeight(smallFont);
    var offsetX as Number = 50;
    var isLowPowerMode = false;


    function initialize() {
        WatchFace.initialize();
        

    
    }

    public function onExitSleep() as Void {
    self.isLowPowerMode = false;
  }

  // Terminate any active timers and prepare for slow updates.
  public function onEnterSleep() as Void {
    self.isLowPowerMode = true;
  }

  function clearScreen(dc as Dc) as Void {
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.clear();
  }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        Device.init(dc);
    
        
            }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        System.println("onShow");
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        Datetime.init();
        var status = Application.Storage.getValue("status") as Dictionary;

        //setTime();
       
        setDate();
        setHeartRate();
        setSteps();
        
        // Set values
        setIOB(status);
        // Don't set COB text - we'll draw it manually
       // setEventualBG(status);
        
        // Hide the COB label by setting it to empty
        var cobLabel = View.findDrawableById("COBLabel") as Text;
        if (cobLabel != null) {
            cobLabel.setText("");
        }
        
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

         
        
        // NOW manually draw the middle section text and position icons
        drawMiddleSection(dc, status);

        //draw the time
        drawTime(dc);

        
    }
    
    function drawMiddleSection(dc as Dc, status) as Void {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        
        // Get font height to adjust icon positioning
        var fontHeight = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var textY = screenHeight * 0.33;
        var iconY = textY - (fontHeight * 0.3);
        
        // Get the icons
        var isfIcon = View.findDrawableById("ISFIcon") as Bitmap;
        var eventualIcon = View.findDrawableById("EventualIcon") as Bitmap;
        
        // Get actual text values
        var iobString = getIOBString(status);
        var eventualString = getEventualBGString(status);
        
        // Determine middle string (COB or sensRatio)
        var middleString = "";
        var showingSensRatio = false;
        
        if (status instanceof Dictionary) {
            var sensRatio = status["sensRatio"];
            var cob = status["cob"];
            
            if (sensRatio != null) {
                middleString = getSensRatioString(status);
                showingSensRatio = true;
            } else if (cob != null) {
                middleString = getCOBString(status);
                showingSensRatio = false;
            } else {
                middleString = "--";
            }
        }
        
        // Calculate text widths
        var iobWidth = dc.getTextWidthInPixels(iobString, Graphics.FONT_MEDIUM);
        var middleWidth = dc.getTextWidthInPixels(middleString, Graphics.FONT_MEDIUM);
        var eventualWidth = dc.getTextWidthInPixels(eventualString, Graphics.FONT_MEDIUM);
        
        // Calculate positions with 2% margins instead of 5%
        var iconSpacing = screenWidth * 0.02;
        var margin = screenWidth * 0.02; // Reduced from 0.05 to 0.02
        
        var iobLeftEdge = margin; // 2% from left edge
        var iobRightEdge = iobLeftEdge + iobWidth;
        
        var eventualRightEdge = screenWidth - margin; // 2% from right edge (98% position)
        var eventualIconWidth = screenWidth * 0.06;
        var eventualIconLeftEdge = eventualRightEdge - eventualWidth - iconSpacing - eventualIconWidth;
        
        // Position eventual icon
        if (eventualIcon != null) {
            eventualIcon.locX = eventualIconLeftEdge;
            eventualIcon.locY = iconY;
        }
        
        // Calculate center of available space
        var availableCenter = (iobRightEdge + eventualIconLeftEdge) / 2;
        
        // Position ISF icon and draw middle text manually
        var isfIconWidth = screenWidth * 0.08;
        
        if (showingSensRatio) {
            // For sensRatio: icon + text should be centered as a unit
            // Calculate total width of icon + spacing + text
            var totalUnitWidth = isfIconWidth + iconSpacing + middleWidth;
            
            // Position icon at the start of the centered unit
            if (isfIcon != null) {
                isfIcon.locX = availableCenter - (totalUnitWidth / 2);
                isfIcon.locY = iconY;
            }
            
            // Text position is after icon + spacing
            var textX = availableCenter - (totalUnitWidth / 2) + isfIconWidth + iconSpacing + (middleWidth / 2);
            
            // Manually draw the middle text at the calculated position
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                textX,
                textY,
                Graphics.FONT_MEDIUM,
                middleString,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else {
            // For COB: same approach - icon + text centered as a unit
            var totalUnitWidth = isfIconWidth + iconSpacing + middleWidth;
            
            if (isfIcon != null) {
                isfIcon.locX = availableCenter - (totalUnitWidth / 2);
                isfIcon.locY = iconY;
            }
            
            var textX = availableCenter - (totalUnitWidth / 2) + isfIconWidth + iconSpacing + (middleWidth / 2);
            
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                textX,
                textY,
                Graphics.FONT_MEDIUM,
                middleString,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        var min = getMinutes(status);
        var loopColor = getLoopColor(min);

        dc.setColor(loopColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        var glucoseHeight = dc.getFontHeight(Graphics.FONT_NUMBER_MILD) as Number;
        dc.drawCircle(screenWidth *0.85, textY, glucoseHeight * 0.3);
        var loopString = (min < 0 ? "--" : min.format("%d"));
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
  
        dc.drawText(screenWidth *0.85,
           textY-glucoseHeight*0.2,
           Graphics.FONT_XTINY,
           loopString,
           Graphics.TEXT_JUSTIFY_CENTER);

    }

    function setCOBorSensRatio(status) as Void {
        var view = View.findDrawableById("COBLabel") as Text;
        
        if (status instanceof Dictionary) {
            var sensRatio = status["sensRatio"];
            var cob = status["cob"];
            
            // Priority to sensRatio if both exist
            if (sensRatio != null) {
                view.setText(getSensRatioString(status));
                // Could update color here for sensRatio if desired
                // view.setColor(Graphics.COLOR_GREEN);
            } else if (cob != null) {
                view.setText(getCOBString(status));
                // view.setColor(Graphics.COLOR_YELLOW);
            } else {
                view.setText("--");
            }
        } else {
            view.setText("--");
        }
    }

    
    
    function getIOBString(status) as String {
        if (status instanceof Dictionary) {
            var iob = status["iob"];
            if (iob instanceof Number) {
                return iob.format("%2.1f") + "U";
            } else if (iob != null) {
                return iob + "U";
            }
        }
        return "--";
    }
    
    function getCOBString(status) as String {
        if (status instanceof Dictionary) {
            var cob = status["cob"]; // actual COB value
            if (cob instanceof Number) {
                return cob.format("%3d") + "g";
            } else if (cob != null) {
                return cob.toString() + "g";
            }
        }
        return "--";
    }
    
    function getSensRatioString(status) as String {
        if (status instanceof Dictionary) {
            var sensRatio = status["sensRatio"]; // sensRatio value
            if (sensRatio instanceof Number) {
                return sensRatio.format("%2.1f");
            } else if (sensRatio != null) {
                return sensRatio.toString();
            }
        }
        return "--";
    }
    
    function getEventualBGString(status) as String {
        if (status instanceof Dictionary) {
            var ebg = status["eventualBGRaw"];
            if (ebg instanceof Number) {
                return ebg.format("%d");
            } else if (ebg != null) {
                return ebg.toString();
            }
        }
        return "--";
    }

    function setTime() as Void {
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var suffix = "";
        if (!System.getDeviceSettings().is24Hour) {
            if (hours >= 12) {
                suffix = " PM";
                if (hours > 12) {
                    hours = hours - 12;
                    }
            } else {
                suffix = " AM";
            }
        } else {
            timeFormat = "$1$:$2$";
            hours = hours.format("%02d");
        }
        var timeString = Lang.format(timeFormat + suffix, [hours, clockTime.min.format("%02d")]);

        // Update the view
        var view = View.findDrawableById("TimeLabel") as TextArea;
        view.setColor(getApp().getProperty("PrimaryColor") as Number);
        view.setText(timeString);
    }

    function setDate() as Void {
        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_MEDIUM);
        // var dateStr = info.day_of_week.substring(0,3) + " " + info.day + "." info.month + ".";
        var dateStr = Lang.format("$1$ $2$.$3$", [info.day_of_week, info.day, info.month]);

        var view = View.findDrawableById("DateLabel") as TextArea;
        view.setColor(getApp().getProperty("PrimaryColor") as Number);
        view.setText(dateStr);
    }

    function setHeartRate() as Void {
        var info = Activity.getActivityInfo();
        var hr = info.currentHeartRate;

        var hrString = (hr == null) ? "--" : hr.toString();

        var view = View.findDrawableById("HRLabel") as Text;
        view.setText(hrString);
    }

    function setSteps() as Void {

        var myStats = System.getSystemStats();
        var batlevel = myStats.battery;
        var batString = Lang.format( "$1$%", [ batlevel.format( "%2d" ) ] );

        var info =  ActivityMonitor.getInfo();
        var steps =   info.steps;
        var stepsString = (steps == null || steps == 0) ? "--" : steps.toString();

        var view = View.findDrawableById("StepsLabel") as Text;
        view.setText(batString);
    }

    function setIOB(status) as Void {
        var view = View.findDrawableById("IOBLabel") as Text;
        view.setText(getIOBString(status));
    }

    function setCOB(status) as Void {
        var view = View.findDrawableById("COBLabel") as Text;
        view.setText(getCOBString(status));
    }

    // function setEventualBG(status) as Void {
    //     var view = View.findDrawableById("EventualBGLabel") as Text;
    //     view.setColor(getApp().getProperty("PrimaryColor") as Number);
    //     view.setText(getEventualBGString(status));
    // }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }


    function getMinutes(status) as Number {

        if (status instanceof Dictionary)  {
            var lastLoopDate = status["lastLoopDateInterval"] as Number;
            if (lastLoopDate == null) {
                return -1;
            }

            var now = Time.now().value() as Number;

            // Calculate seconds difference
            var deltaSeconds = now - lastLoopDate;

            // Round up to the nearest minute if delta is positive
            var min = (deltaSeconds > 0) ? ((deltaSeconds + 59) / 60) : 0;

            return min;
        } else {
            return -1;
        }

    }

    function getLoopColor(min as Number) as Number {
        if (min < 0) {
            return Graphics.COLOR_LT_GRAY as Number;
        } else if (min <= 7) {
            return Graphics.COLOR_GREEN as Number;
        } else if (min <= 12) {
            return Graphics.COLOR_YELLOW as Number;
        } else {
            return Graphics.COLOR_RED as Number;
        }
    }

    function drawTime(dc as Dc) as Void {
            var textAlign = Graphics.TEXT_JUSTIFY_VCENTER;
            var timeFontSize = Graphics.FONT_NUMBER_HOT;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

            // Time
            dc.drawText(
            Device.screenSize.x -
                offsetX * (timeFontSize == Graphics.FONT_NUMBER_HOT ? 1.9 : 0.75),
            Device.screenCenter.y*1.11,
            timeFontSize,
            Datetime.getTimeText(),
            textAlign
            );

            // // AM/PM
            // dc.drawText(
            // Device.screenSize.x - 10,
            // Device.screenCenter.y - smallFontSize / 2,
            // smallFont,
            // Datetime.getAmPm(),
            // textAlign
            // );

            if (!self.isLowPowerMode) {
            // Seconds
            dc.drawText(
                Device.screenSize.x - 50,
                Device.screenCenter.y + smallFontSize / 2,
                smallFont,
                Datetime.getSecondsText(),
                textAlign
            );
        }
  }
}