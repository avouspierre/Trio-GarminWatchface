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
        drawHeaderSection(dc, status);  // draws header manually
        drawMiddleSection(dc, status);  // draws middle section
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
        
        // Calculate positions with 2% margins
        var iconSpacing = screenWidth * 0.005;
        var margin = screenWidth * 0.02;
        
        var iobLeftEdge = margin;
        var iobRightEdge = iobLeftEdge + iobWidth;
        
        var eventualRightEdge = screenWidth - margin;
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
        
        // Dynamic positioning based on screen size
        var baseY;
        var sideMargin;
        var circleRadius;
        var circlePenWidth;
        
        if (screenWidth <= 240) {
            baseY = screenHeight * 0.25;
            sideMargin = screenWidth * 0.08;
            circleRadius = glucoseHeight * 0.35;
            circlePenWidth = 4;
        } else {
            baseY = screenHeight * 0.2;
            sideMargin = screenWidth * 0.06;
            circleRadius = glucoseHeight * 0.2;
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
        var arrowWidth = screenWidth * 0.08;
        
        // 3. Draw loop circle and time (right side - time BEFORE circle)
        var loopGroupWidth = loopWidth + elementSpacing + (circleRadius * 2) + circlePenWidth;
        var loopGroupStartX = screenWidth - sideMargin - loopGroupWidth;
        
        // Draw loop time FIRST
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
        var deltaEndX = loopGroupStartX - elementSpacing;
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
            
            // Convert to number first, then divide
            var lastLoopMs = lastLoopDate.toLong();    // Handles large values
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
            
            // Force integer division by converting to long first
            var minutes = (deltaSeconds / 60).toLong();
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