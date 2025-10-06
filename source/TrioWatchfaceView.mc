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

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {
        System.println("onShow");
    }

    function onUpdate(dc as Dc) as Void {
        var status = Application.Storage.getValue("status") as Dictionary;

        setTime();
        setDate();
        setHeartRate();
        setSteps();
        
        View.onUpdate(dc);
        
        drawMiddleSection(dc, status);
        drawHeaderSection(dc, status);
    }
    
    function isMMOL(status) as Boolean {
        if (status instanceof Dictionary) {
            var unitsHint = status["units_hint"];
            return (unitsHint != null && unitsHint.equals("mmol"));
        }
        return false;
    }
    
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
        
        var baseY;
        if (screenWidth <= 240) {
            baseY = screenHeight * 0.32;
        } else {
            baseY = screenHeight * 0.33;
        }
        
        var fontHeight = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var textY = baseY;
        var iconY = textY - (fontHeight * 0.2);
        
        var isfIcon = View.findDrawableById("ISFIcon") as Bitmap;
        var eventualIcon = View.findDrawableById("EventualIcon") as Bitmap;
        
        var iobValue = getIOBValue(status);
        var eventualString = getEventualBGString(status);
        
        var middleValue = "";
        var showingSensRatio = false;
        
        if (status instanceof Dictionary) {
            var sensRatio = status["sensRatio"];
            var cob = status["cob"];
            
            if (sensRatio != null) {
                middleValue = getSensRatioString(status);
                showingSensRatio = true;
            } else if (cob != null) {
                middleValue = getCOBValue(status);
                showingSensRatio = false;
            } else {
                middleValue = "--";
            }
        }
        
        var iobWidth = dc.getTextWidthInPixels(iobValue, Graphics.FONT_MEDIUM);
        var iobUnitWidth = dc.getTextWidthInPixels("U", Graphics.FONT_XTINY);
        var middleWidth = dc.getTextWidthInPixels(middleValue, Graphics.FONT_MEDIUM);
        var eventualWidth = dc.getTextWidthInPixels(eventualString, Graphics.FONT_MEDIUM);
        
        var iconSpacing = screenWidth * 0.015;
        var unitSpacing = screenWidth * 0.005;
        var margin = screenWidth * 0.07;
        
        var iobLeftEdge = margin;
        var iobTotalWidth = iobWidth + unitSpacing + iobUnitWidth;
        var iobRightEdge = iobLeftEdge + iobTotalWidth;
        
        var eventualRightEdge = screenWidth - margin;
        var eventualIconWidth = screenWidth * 0.06;
        var eventualIconLeftEdge = eventualRightEdge - eventualWidth - iconSpacing - eventualIconWidth;

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            iobLeftEdge,
            textY,
            Graphics.FONT_MEDIUM,
            iobValue,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        var unitY = textY + (dc.getFontHeight(Graphics.FONT_XTINY)) * 0.2;
        dc.drawText(
            iobLeftEdge + iobWidth + unitSpacing,
            unitY,
            Graphics.FONT_XTINY,
            "U",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        if (eventualIcon != null) {
            eventualIcon.locX = eventualIconLeftEdge;
            eventualIcon.locY = iconY;
        }
        
        var primaryColor = getApp().getProperty("PrimaryColor") as Number;
        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            eventualRightEdge,
            textY,
            Graphics.FONT_MEDIUM,
            eventualString,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        var availableCenter = (iobRightEdge + eventualIconLeftEdge) / 2;
        var isfIconWidth = screenWidth * 0.06;
        
        if (showingSensRatio) {
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
                middleValue,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else {
            if (isfIcon != null) {
                isfIcon.locX = -100;
            }
            
            var cobUnitWidth = dc.getTextWidthInPixels("g", Graphics.FONT_XTINY);
            var cobTotalWidth = middleWidth + unitSpacing + cobUnitWidth;
            var cobStartX = availableCenter - (cobTotalWidth / 2);
            
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                cobStartX,
                textY,
                Graphics.FONT_MEDIUM,
                middleValue,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.drawText(
                cobStartX + middleWidth + unitSpacing,
                unitY,
                Graphics.FONT_XTINY,
                "g",
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
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
        
        var glucoseText = getGlucoseText(status);
        var deltaText = getDeltaText(status);
        var loopMinutes = getLoopMinutes(status);
        var loopText = (loopMinutes < 0 ? "--" : loopMinutes.format("%d")) + "m";
        
        var glucoseHeight = dc.getFontHeight(glucoseFont);
        
        var glucoseWidth = dc.getTextWidthInPixels(glucoseText, glucoseFont);
        var deltaWidth = dc.getTextWidthInPixels(deltaText, deltaFont);
        var loopWidth = dc.getTextWidthInPixels(loopText, secondaryFont);
        
        var baseY = screenHeight * 0.51;
        var sideMargin = screenWidth * 0.005;
        var circleRadius = glucoseHeight * 0.4;
        var circlePenWidth = 4;
        
        if (screenWidth > 240) {
            circlePenWidth = ((screenWidth * 0.015).toNumber());
            circleRadius = glucoseHeight * 0.25;
            if (circlePenWidth < 3) { circlePenWidth = 3; }
            if (circlePenWidth > 6) { circlePenWidth = 6; }
        }

        
        var elementSpacing = screenWidth * 0.015;
        var arrowWidth = screenWidth * 0.06;
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            sideMargin,
            baseY,
            deltaFont,
            deltaText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        var deltaRightEdge = sideMargin + deltaWidth;
        
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
        
        var availableStart = deltaRightEdge + elementSpacing;
        var availableEnd = loopGroupStartX - elementSpacing;
        var availableCenter = (availableStart + availableEnd) / 2;
        
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
                return -1;
            }
            
            var lastLoopMs = lastLoopDate.toLong();
            var lastLoopSeconds = lastLoopMs / 1000;
            
            var now = Time.now().value();
            var deltaSeconds = now - lastLoopSeconds;
            
            if (deltaSeconds <= 0) {
                return 0;
            }
            
            var minutes = (deltaSeconds / 60).toNumber();
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

    function getIOBValue(status) as String {
        if (status instanceof Dictionary) {
            var iob = status["iob"];
            if (iob instanceof Number || iob instanceof Float || iob instanceof Double) {
                return iob.format("%2.1f");
            } else if (iob != null) {
                return iob.toString();
            }
        }
        return "--";
    }
    
    function getCOBValue(status) as String {
        if (status instanceof Dictionary) {
            var cob = status["cob"];
            if (cob instanceof Number || cob instanceof Float || cob instanceof Double) {
                return cob.format("%d");
            } else if (cob != null) {
                return cob.toString();
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

        var view = View.findDrawableById("StepsLabel") as Text;
        view.setText(batString);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }
}