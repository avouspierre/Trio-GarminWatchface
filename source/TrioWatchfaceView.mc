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
        
        // DEBUG: Print what we received
        System.println("=== DEBUG onUpdate ===");
        if (status == null) {
            System.println("ERROR: status is null!");
        } else if (!(status instanceof Dictionary)) {
            System.println("ERROR: status is not a Dictionary!");
        } else {
            System.println("Status data received:");
            System.println("  sgv: " + status["sgv"]);
            System.println("  delta: " + status["delta"]);
            System.println("  direction: " + status["direction"]);
            System.println("  date: " + status["date"]);
            System.println("  eventualBG: " + status["eventualBG"]);
            System.println("  iob: " + status["iob"]);
            System.println("  cob: " + status["cob"]);
            System.println("  sensRatio: " + status["sensRatio"]);
            System.println("  units_hint: " + status["units_hint"]);
        }
        System.println("=== END DEBUG ===");

        setTime();
        setDate();
        setHeartRate();
        setSteps();
        
        // Hide all the labels - we'll draw everything manually
        var iobLabel = View.findDrawableById("IOBLabel") as Text;
        if (iobLabel != null) {
            iobLabel.setText("");
        }
        var cobLabel = View.findDrawableById("COBLabel") as Text;
        if (cobLabel != null) {
            cobLabel.setText("");
        }
        var eventualLabel = View.findDrawableById("EventualBGLabel") as Text;
        if (eventualLabel != null) {
            eventualLabel.setText("");
        }
        
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        // NOW manually draw both the header and middle sections
        drawMiddleSection(dc, status);  // draws IOB/COB/Eventual row
        drawHeaderSection(dc, status);  // draws glucose/delta/loop row
    }
    
    // Helper function to check if units are mmol/L
    function isMMOL(status) as Boolean {
        if (status instanceof Dictionary) {
            var unitsHint = status["units_hint"];
            return (unitsHint != null && unitsHint.equals("mmol"));
        }
        return false;
    }
    
    // Helper function to convert mg/dL to mmol/L if needed
    function convertGlucoseValue(value, status) as Float {
        if (value instanceof Number) {
            if (isMMOL(status)) {
                return value * 0.05556;
            }
            return value.toFloat();
        }
        return 0.0;
    }
    
    function drawMiddleSection(dc as Dc, status) as Void {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        
        // Move to header position (20-25% down from top)
        var baseY;
        if (screenWidth <= 240) {
            baseY = screenHeight * 0.37;
        } else {
            baseY = screenHeight * 0.32;
        }
        
        // Get font height to adjust icon positioning
        var fontHeight = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var textY = baseY;
        var iconY = textY - (fontHeight * 0.2);
        
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
        
        // Use header-style margins (6-8% instead of 2%)
        var iconSpacing = screenWidth * 0.015;
        var margin = screenWidth * 0.05;
        
        var iobLeftEdge = margin;
        var iobRightEdge = iobLeftEdge + iobWidth;
        
        var eventualRightEdge = screenWidth - margin;
        var eventualIconWidth = screenWidth * 0.06;
        var eventualIconLeftEdge = eventualRightEdge - eventualWidth - iconSpacing - eventualIconWidth;

        // 1. Draw IOB text (left side)
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            iobLeftEdge,
            textY,
            Graphics.FONT_MEDIUM,
            iobString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // 2. Position and draw eventual icon
        if (eventualIcon != null) {
            eventualIcon.locX = eventualIconLeftEdge;
            eventualIcon.locY = iconY;
        }
        
        // 3. Draw Eventual BG text (right side)
        var primaryColor = getApp().getProperty("PrimaryColor") as Number;
        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            eventualRightEdge,
            textY,
            Graphics.FONT_MEDIUM,
            eventualString,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Calculate center of available space
        var availableCenter = (iobRightEdge + eventualIconLeftEdge) / 2;
        
        // Position ISF icon and draw middle text (COB or sensRatio)
        var isfIconWidth = screenWidth * 0.06;
        
        if (showingSensRatio) {
            // For sensRatio: icon + text should be centered as a unit
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
        } else {
            // For COB: no icon, yellow text, centered directly
            if (isfIcon != null) {
                isfIcon.locX = -100; // Move off screen
            }
            
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

    function drawHeaderSection(dc as Dc, status) as Void {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        var primaryColor = getApp().getProperty("PrimaryColor") as Number;
        
        var glucoseFont = Graphics.FONT_NUMBER_MILD;
        var deltaFont = Graphics.FONT_MEDIUM;
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
        
        // Move to middle position (51% down) with tight margins
        var baseY = screenHeight * 0.51;
        var sideMargin = screenWidth * 0.005;
        var circleRadius = glucoseHeight * 0.2;
        var circlePenWidth = 6;
        
        if (screenWidth > 240) {
            circlePenWidth = ((screenWidth * 0.015).toNumber());
            if (circlePenWidth < 3) { circlePenWidth = 3; }
            if (circlePenWidth > 6) { circlePenWidth = 6; }
        }
        
        var elementSpacing = screenWidth * 0.015;
        var arrowWidth = screenWidth * 0.06;
        
        // 1. Draw delta (LEFT side)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            sideMargin,
            baseY,
            deltaFont,
            deltaText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Calculate where delta ends
        var deltaRightEdge = sideMargin + deltaWidth;
        
        // 2. Draw loop time and circle (RIGHT side)
        var loopGroupWidth = loopWidth + elementSpacing + (circleRadius * 2) + circlePenWidth;
        var loopGroupStartX = screenWidth - sideMargin - loopGroupWidth;
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            loopGroupStartX,
            baseY,
            secondaryFont,
            loopText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        var circleX = loopGroupStartX + loopWidth + elementSpacing + circleRadius + (circlePenWidth/2);
        var circleY = baseY;
        
        var loopColor = getLoopColor(loopMinutes);
        dc.setColor(loopColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(circlePenWidth);
        dc.drawCircle(circleX, circleY, circleRadius);
        
        // 3. Draw glucose + arrow (CENTERED between delta and loop)
        // Calculate the available space between delta and loop
        var availableStart = deltaRightEdge + elementSpacing;
        var availableEnd = loopGroupStartX - elementSpacing;
        var availableCenter = (availableStart + availableEnd) / 2;
        
        // Calculate glucose+arrow as a unit
        var glucoseArrowWidth = glucoseWidth + elementSpacing + arrowWidth;
        var glucoseX = availableCenter - (glucoseArrowWidth / 2);
        
        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            glucoseX,
            baseY,
            glucoseFont,
            glucoseText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        var arrowX = glucoseX + glucoseWidth + elementSpacing;
        var arrowY = baseY - arrowWidth / 2;
        var arrowBitmap = getDirectionBitmap(status);
        if (arrowBitmap != null) {
            dc.drawBitmap(arrowX, arrowY, arrowBitmap);
        }
    }
    
    // Helper functions for header
    function getGlucoseText(status) as String {
        if (status instanceof Dictionary) {
            var glucose = status["sgv"];
            if (glucose instanceof Number || glucose instanceof Float || glucose instanceof Double) {
                var convertedValue = convertGlucoseValue(glucose, status);
                if (isMMOL(status)) {
                    return convertedValue.format("%2.1f");
                } else {
                    return convertedValue.format("%d");
                }
            }
        }
        return "--";
    }
    
    function getDeltaText(status) as String {
        if (status instanceof Dictionary) {
            var delta = status["delta"];
            if (delta instanceof Number || delta instanceof Float || delta instanceof Double) {
                var convertedValue = convertGlucoseValue(delta, status);
                var sign = (delta >= 0) ? "+" : "";
                if (isMMOL(status)) {
                    return sign + convertedValue.format("%2.1f");
                } else {
                    return sign + convertedValue.format("%d");
                }
            }
        }
        return "--";
    }
    
    function getDirectionBitmap(status) as BitmapType {
        var bitmap = WatchUi.loadResource(Rez.Drawables.Unknown);
        if (status instanceof Dictionary) {
            var trend = status["direction"] as String;
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
            var lastLoopDate = status["date"];
            if (lastLoopDate == null) {
                System.println("ERROR: date field is null");
                return -1;
            }
            
            // Use toLong() to handle large millisecond timestamps
            var lastLoopMs = lastLoopDate.toLong();
            var lastLoopSeconds = lastLoopMs / 1000;
            
            var now = Time.now().value();
            var deltaSeconds = now - lastLoopSeconds;
            
            System.println("Loop calculation:");
            System.println("  lastLoopMs: " + lastLoopMs);
            System.println("  lastLoopSeconds: " + lastLoopSeconds);
            System.println("  now: " + now);
            System.println("  deltaSeconds: " + deltaSeconds);
            
            if (deltaSeconds <= 0) {
                return 0;
            }
            
            // Convert to minutes as integer
            var minutes = (deltaSeconds / 60).toNumber();
            System.println("  minutes: " + minutes);
            return minutes;
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

    function getIOBString(status) as String {
        if (status instanceof Dictionary) {
            var iob = status["iob"];
            if (iob instanceof Number || iob instanceof Float || iob instanceof Double) {
                return iob.format("%2.1f") + "U";
            } else if (iob != null) {
                return iob.toString() + "U";
            }
        }
        return "--";
    }
    
    function getCOBString(status) as String {
        if (status instanceof Dictionary) {
            var cob = status["cob"];
            if (cob instanceof Number || cob instanceof Float || cob instanceof Double) {
                return cob.format("%d") + "g";
            } else if (cob != null) {
                return cob.toString() + "g";
            }
        }
        return "--";
    }
    
    function getSensRatioString(status) as String {
        if (status instanceof Dictionary) {
            var sensRatio = status["sensRatio"];
            if (sensRatio instanceof Number || sensRatio instanceof Float || sensRatio instanceof Double) {
                return sensRatio.format("%2.2f");
            } else if (sensRatio != null) {
                return sensRatio.toString();
            }
        }
        return "--";
    }
    
    function getEventualBGString(status) as String {
        if (status instanceof Dictionary) {
            var ebg = status["eventualBG"];
            if (ebg instanceof Number || ebg instanceof Float || ebg instanceof Double) {
                var convertedValue = convertGlucoseValue(ebg, status);
                if (isMMOL(status)) {
                    return convertedValue.format("%2.1f");
                } else {
                    return convertedValue.format("%d");
                }
            }
        }
        return "--";
    }

    function setTime() as Void {
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

        var view = View.findDrawableById("TimeLabel") as TextArea;
        view.setColor(getApp().getProperty("PrimaryColor") as Number);
        view.setText(timeString);
    }

    function setDate() as Void {
        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_MEDIUM);
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

    function setEventualBG(status) as Void {
        var view = View.findDrawableById("EventualBGLabel") as Text;
        view.setColor(getApp().getProperty("PrimaryColor") as Number);
        view.setText(getEventualBGString(status));
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }
}