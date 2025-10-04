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

class TrioWatchfaceView extends WatchUi.WatchFace {
    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        System.println("onShow");
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {

        var status = Application.Storage.getValue("status") as Dictionary;

        setTime();
        setDate();
        setHeartRate();
        setSteps();
        
        // Set values and then dynamically position middle section
        setIOB(status);
        setCOBorSensRatio(status);  // Handle either COB or sensRatio
        setEventualBG(status);
        
        // Now dynamically adjust positions based on actual text widths
        adjustMiddleSectionPositions(dc, status);
        
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
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

    function adjustMiddleSectionPositions(dc as Dc, status) as Void {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        
        // Get font height to adjust icon positioning
        var fontHeight = dc.getFontHeight(Graphics.FONT_MEDIUM);
        
        // Text is at 50% height, but icons need to be adjusted up by half font height
        // to align their centers with the text baseline
        var textY = screenHeight * 0.5;
        var iconY = textY - (fontHeight * 0.3);
        
        // Get the views - cast icons as Bitmap
        var iobLabel = View.findDrawableById("IOBLabel");
        var cobLabel = View.findDrawableById("COBLabel"); // This label shows either COB or sensRatio
        var isfIcon = View.findDrawableById("ISFIcon") as Bitmap;
        var eventualLabel = View.findDrawableById("EventualBGLabel");
        var eventualIcon = View.findDrawableById("EventualIcon") as Bitmap;
        
        // Get actual text values
        var iobString = getIOBString(status);
        var eventualString = getEventualBGString(status);
        
        // Determine if we're showing COB or sensRatio
        var middleString = "";
        var showingSensRatio = false;
        
        if (status instanceof Dictionary) {
            var sensRatio = status["sensRatio"];
            var cob = status["cob"];
            
            // Priority to sensRatio if both exist, or show whichever is available
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
        
        // Define spacing
        var iconSpacing = screenWidth * 0.02; // 2% space between icon and text
        
        // Position IOB (left-aligned at 5% margin)
        if (iobLabel != null) {
            iobLabel.locX = screenWidth * 0.05; // Left edge at 5% (since it's left-justified)
        }
        
        // Position middle element (COB or sensRatio) at center
        if (cobLabel != null) {
            cobLabel.setText(middleString); // Update text to either COB or sensRatio
            
            if (showingSensRatio) {
                // For sensRatio: center position with icon to its left
                cobLabel.locX = screenWidth / 2; // Center (since it's center-justified)
                
                // Position icon to the left of sensRatio text
                if (isfIcon != null) {
                    isfIcon.locX = (screenWidth / 2) - (middleWidth / 2) - iconSpacing - (screenWidth * 0.06);
                    isfIcon.locY = iconY; // Adjusted up by half font height
                }
                
            } else {
                // For COB: icon on left, text on right, both centered
                if (isfIcon != null) {
                    var iconWidth = screenWidth * 0.06;
                    var totalWidth = iconWidth + iconSpacing + middleWidth;
                    var startX = (screenWidth - totalWidth) / 2;
                    
                    isfIcon.locX = startX;
                    isfIcon.locY = iconY; // Adjusted up by half font height
                    cobLabel.locX = screenWidth / 2; // Keep centered
                }
            }
        }
        
        // Position Eventual BG (right-aligned at 95% like aiSR in datafield)
        if (eventualLabel != null && eventualIcon != null) {
            // Right-align the text at 95% of screen width
            eventualLabel.locX = screenWidth * 0.95; // Right edge at 95% (since it's right-justified)
            
            // Position icon to the left of eventual BG text
            eventualIcon.locX = (screenWidth * 0.95) - eventualWidth - iconSpacing - (screenWidth * 0.05);
            eventualIcon.locY = iconY; // Adjusted up by half font height
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

    function setEventualBG(status) as Void {
        var view = View.findDrawableById("EventualBGLabel") as Text;
        view.setColor(getApp().getProperty("PrimaryColor") as Number);
        view.setText(getEventualBGString(status));
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }
}