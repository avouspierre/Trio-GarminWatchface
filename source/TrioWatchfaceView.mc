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

    function onUpdate(dc as Dc) as Void {
        var status = Application.Storage.getValue("status") as Dictionary;

        setTime();
        setDate();
        setHeartRate();
        setSteps();
        
        // Set values
        setIOB(status);
        // Don't set COB text - we'll draw it manually
        setEventualBG(status);
        
        // Hide the COB label by setting it to empty
        var cobLabel = View.findDrawableById("COBLabel") as Text;
        if (cobLabel != null) {
            cobLabel.setText("");
        }
        
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        // NOW manually draw both the header and middle sections
        drawHeaderSection(dc, status);  // NEW LINE - draws header manually
        drawMiddleSection(dc, status);  // EXISTING - draws middle section
    }
    
    function drawMiddleSection(dc as Dc, status) as Void {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        
        // Get font height to adjust icon positioning
        var fontHeight = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var textY = screenHeight * 0.5;
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
        var iconSpacing = screenWidth * 0.005;
        var margin = screenWidth * 0.02; // Reduced from 0.05 to 0.02
        
        var iobLeftEdge = margin; // 2% from left edge
        var iobRightEdge = iobLeftEdge + iobWidth;
        
        var eventualRightEdge = screenWidth - margin; // 2% from right edge (98% position)
        var eventualIconWidth = screenWidth * 0.06;
        // Position icon much closer - just the width of the text plus small gap
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
            // For COB: no icon, yellow text, centered directly
            // Hide the ISF icon
            if (isfIcon != null) {
                isfIcon.locX = -100; // Move off screen to hide it
            }
            
            // Draw COB text in yellow at the available center
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                availableCenter,
                textY,
                Graphics.FONT_MEDIUM,
                middleString,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

// Add this function to your existing TrioWatchfaceView.mc file
// This goes right after your drawMiddleSection function

    function drawHeaderSection(dc as Dc, status) as Void {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        var primaryColor = getApp().getProperty("PrimaryColor") as Number;
        
        // Keep font sizes smaller - FONT_NUMBER_MILD for all watch sizes
        var glucoseFont = Graphics.FONT_NUMBER_MILD;
        var deltaFont = Graphics.FONT_MEDIUM;  // One size smaller than NUMBER_MILD
        var secondaryFont = Graphics.FONT_TINY;
        
        // Get text values
        var glucoseText = getGlucoseText(status);
        var deltaText = getDeltaText(status);
        var loopMinutes = getLoopMinutes(status);
        var loopText = (loopMinutes < 0 ? "--" : loopMinutes.format("%d")) + "m";
        
        // Get font dimensions
        var glucoseHeight = dc.getFontHeight(glucoseFont);
        var deltaHeight = dc.getFontHeight(deltaFont);
        var secondaryHeight = dc.getFontHeight(secondaryFont);
        
        // Calculate text widths
        var glucoseWidth = dc.getTextWidthInPixels(glucoseText, glucoseFont);
        var deltaWidth = dc.getTextWidthInPixels(deltaText, deltaFont);
        var loopWidth = dc.getTextWidthInPixels(loopText, secondaryFont);
        
        // Dynamic positioning and sizing based on screen size
        var baseY;
        var sideMargin;
        var circleRadius;
        var circlePenWidth;
        
        if (screenWidth <= 240) { // Fenix 5 and similar small screens
            baseY = screenHeight * 0.25; // Lower position to avoid time overlap
            sideMargin = screenWidth * 0.08; // More margin (8% vs 6%)
            circleRadius = glucoseHeight * 0.35; // Bigger circle
            circlePenWidth = 4; // Fixed 4px for small screens
        } else { // Larger screens (Enduro 3, newer watches)
            baseY = screenHeight * 0.2; // Position works fine for larger screens
            sideMargin = screenWidth * 0.06; // Standard margin
            circleRadius = glucoseHeight * 0.2; // Standard circle size
            // Simple integer conversion without Math.round
            circlePenWidth = ((screenWidth * 0.018).toNumber());
            if (circlePenWidth < 4) { circlePenWidth = 4; }
            if (circlePenWidth > 8) { circlePenWidth = 8; }
        }
        
        var elementSpacing = screenWidth * 0.02;
        
        // 1. Draw glucose (left side)
        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            sideMargin,
            baseY,
            glucoseFont,
            glucoseText,
            Graphics.TEXT_JUSTIFY_LEFT
        );
        
        // 2. Draw arrow after glucose
        var arrowX = sideMargin + glucoseWidth + elementSpacing;
        var arrowY = baseY + glucoseHeight * 0.3;
        var arrowBitmap = getDirectionBitmap(status);
        if (arrowBitmap != null) {
            dc.drawBitmap(arrowX, arrowY, arrowBitmap);
        }
        var arrowWidth = screenWidth * 0.08; // Estimate arrow width
        
        // 3. Draw loop circle and time (right side - time BEFORE circle)
        // Calculate right-aligned position for the GROUP (time + circle)
        var loopGroupWidth = loopWidth + elementSpacing + (circleRadius * 2) + circlePenWidth;
        var loopGroupStartX = screenWidth - sideMargin - loopGroupWidth;
        
        // Draw loop time FIRST (on the left of circle)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            loopGroupStartX,
            baseY + (glucoseHeight - secondaryHeight) / 2,
            secondaryFont,
            loopText,
            Graphics.TEXT_JUSTIFY_LEFT
        );
        
        // Draw circle AFTER the time text
        var circleX = loopGroupStartX + loopWidth + elementSpacing + circleRadius + (circlePenWidth/2);
        var circleY = baseY + (glucoseHeight / 2);
        
        var loopColor = getLoopColor(loopMinutes);
        dc.setColor(loopColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(circlePenWidth);
        dc.drawCircle(circleX, circleY, circleRadius);
        
        // 4. Draw delta (centered in remaining space)
        var deltaStartX = arrowX + arrowWidth + elementSpacing;
        var deltaEndX = loopGroupStartX - elementSpacing;  // Use loopGroupStartX instead of circleX
        var deltaCenterX = (deltaStartX + deltaEndX) / 2;
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            deltaCenterX,
            baseY + (glucoseHeight - deltaHeight) / 2,
            deltaFont,
            deltaText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
    
    // Helper functions for header - add these if they don't exist
    function getGlucoseText(status) as String {
        if (status instanceof Dictionary) {
            var glucose = status["glucose"];
            return (glucose == null) ? "--" : glucose.toString();
        }
        return "--";
    }
    
    function getDeltaText(status) as String {
        if (status instanceof Dictionary) {
            var delta = status["delta"];
            return (delta == null) ? "--" : delta.toString();
        }
        return "--";
    }
    
    function getDirectionBitmap(status) as BitmapType {
        var bitmap = WatchUi.loadResource(Rez.Drawables.Unknown);
        if (status instanceof Dictionary) {
            var trend = status["trendRaw"] as String;
            if (trend == null) {
                return bitmap;
            }
            
            switch (trend) {
                case "Flat":
                    bitmap = WatchUi.loadResource(Rez.Drawables.Flat);
                    break;
                case "SingleUp":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleUp);
                    break;
                case "SingleDown":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleDown);
                    break;
                case "FortyFiveUp":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveUp);
                    break;
                case "FortyFiveDown":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveDown);
                    break;
                case "DoubleUp":
                case "TripleUp":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleUp);
                    break;
                case "DoubleDown":
                case "TripleDown":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleDown);
                    break;
            }
        }
        return bitmap;
    }
    
    function getLoopMinutes(status) as Number {
        if (status instanceof Dictionary) {
            var lastLoopDate = status["lastLoopDateInterval"] as Number;
            if (lastLoopDate == null) {
                return -1;
            }
            
            var now = Time.now().value() as Number;
            var deltaSeconds = now - lastLoopDate;
            var min = (deltaSeconds > 0) ? ((deltaSeconds + 59) / 60) : 0;
            return min;
        }
        return -1;
    }
    
    function getLoopColor(min as Number) as Number {
        if (min < 0) {
            return Graphics.COLOR_LT_GRAY;
        } else if (min <= 7) {
            return Graphics.COLOR_GREEN;
        } else if (min <= 12) {
            return Graphics.COLOR_YELLOW;
        } else {
            return Graphics.COLOR_RED;
        }
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
        var iconSpacing = screenWidth * 0.04; // 2% space between icon and text
        
        // Position IOB (left-aligned at 5% margin)
        var iobLeftEdge = screenWidth * 0.05;
        if (iobLabel != null) {
            iobLabel.locX = iobLeftEdge; // Left edge at 5% (since it's left-justified)
        }
        var iobRightEdge = iobLeftEdge + iobWidth;
        
        // Position Eventual BG first to know its icon position
        var eventualRightEdge = screenWidth * 0.95;
        var eventualIconWidth = screenWidth * 0.06; // 6% as defined in layout.xml
        var eventualIconLeftEdge = eventualRightEdge - eventualWidth - eventualIconWidth;
        
        if (eventualLabel != null && eventualIcon != null) {
            // Right-align the text at 95% of screen width
            eventualLabel.locX = eventualRightEdge; // Right edge at 95% (since it's right-justified)
            
            // Position icon to the left of eventual BG text
            eventualIcon.locX = eventualIconLeftEdge;
            eventualIcon.locY = iconY; // Adjusted up by half font height
        }
        
        // Now position middle element (COB or sensRatio) centered in the available space
        // Available space is between IOB right edge and eventual BG icon left edge
        var availableCenter = (iobRightEdge + eventualIconLeftEdge) / 2;
        
        // Debug: Let's verify the calculation
        System.println("IOB right edge: " + iobRightEdge);
        System.println("Eventual icon left edge: " + eventualIconLeftEdge);
        System.println("Available center: " + availableCenter);
        System.println("Screen center: " + (screenWidth / 2));
        
        if (cobLabel != null) {
            // Set position FIRST, before setText
            cobLabel.locX = availableCenter; // This should move it from screen center
            
            // Then set the text
            cobLabel.setText(middleString); // Update text to either COB or sensRatio
            
            if (showingSensRatio) {
                // For sensRatio: center position in available space with icon to its left
                cobLabel.locX = availableCenter; // Center in available space
                
                // Position icon to the left of sensRatio text
                if (isfIcon != null) {
                    var isfIconWidth = screenWidth * 0.08; // 8% as defined in layout.xml
                    isfIcon.locX = availableCenter - (middleWidth / 2) - iconSpacing - isfIconWidth;
                    isfIcon.locY = iconY; // Adjusted up by half font height
                }
                
            } else {
                // For COB: icon on left, text on right, both centered in available space
                if (isfIcon != null) {
                    var iconWidth = screenWidth * 0.08; // 8% as defined in layout.xml
                    var totalWidth = iconWidth + iconSpacing + middleWidth;
                    var startX = availableCenter - (totalWidth / 2);
                    
                    isfIcon.locX = startX;
                    isfIcon.locY = iconY; // Adjusted up by half font height
                    cobLabel.locX = availableCenter; // Center in available space
                }
            }
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