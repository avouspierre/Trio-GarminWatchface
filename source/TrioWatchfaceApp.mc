//**********************************************************************
// DESCRIPTION : Watch Faces for Trio - Optimized Version
// AUTHORS :
//          Created by ivalkou - https://github.com/ivalkou
//          Modify by Pierre Lagarde - https://github.com/avouspierre
// COPYRIGHT : (c) 2023 ivalkou / Lagarde
//
// OPTIMIZED: 320s backup timer, reset on data receive

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.Time;
import Toybox.System;
import Toybox.Communications;

(:background)
class TrioWatchfaceApp extends Application.AppBase {

    var inBackground=false;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        //register for temporal events if they are supported
        if(Toybox.System has :ServiceDelegate) {
            // OPTIMIZED: Changed from 300s to 320s for backup sync
            Background.registerForTemporalEvent(new Time.Duration(320));
            if (Background has :registerForPhoneAppMessageEvent) {
                Background.registerForPhoneAppMessageEvent();
                System.println("****background is ok****");
            } else {
                System.println("****registerForPhoneAppMessageEvent is not available****");
            }

        } else {
            System.println("****background not available on this device****");
        }

        // Get the current Unix time
        var now = Time.now().value();
        var fourMinutesAgo = now - 240; // 4 minutes ago in seconds

        // Simulate data for testing in the simulator - using original string format
        var sampleData = {
            "glucose" => "244",
            "trendRaw" => "DoubleUp", 
            "delta" => "-27",
            "iob" => "10.9",
            "cob" => "20",
            "lastLoopDateInterval" => fourMinutesAgo,
            "eventualBGRaw" => "85",
            "isf" => "100",
            //"sensRatio" => "0.9"
        } as Dictionary;

        var sampleDataMmol = {
            "glucose" => "10.8",
            "trendRaw" => "DoubleUp", 
            "delta" => "-4.8",
            "iob" => "10.9",
            "cob" => "20",
            "lastLoopDateInterval" => fourMinutesAgo,
            "eventualBGRaw" => "12.9",
            "isf" => "4.9",
            "sensRatio" => "0.9"
        } as Dictionary;

        // Store the sample data (uncomment one to test)
        //Application.Storage.setValue("status", sampleData);
    }

    function onBackgroundData(data) {
        if (data instanceof Number || data == null) {
            System.println("Not a dictionary");
        } else {
            System.println("try to update the status");
            
            // OPTIMIZED: ALWAYS reset timer when valid data is received
            Background.deleteTemporalEvent(); // Delete old timer
            Background.registerForTemporalEvent(new Time.Duration(320)); // Register new 320s timer
            
            if (Background has :registerForPhoneAppMessageEvent) {
                System.println("updated with registerForPhoneAppMessageEvent");
                // Modern devices: data is already handled via onPhoneAppMessage
            } else {
                System.println("update status");
                Application.Storage.setValue("status", data as Dictionary);
            }
        }
        
        System.println("requestUpdate");
        WatchUi.requestUpdate();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        if(!inBackground) {
            System.println("stop temp event");
    		Background.deleteTemporalEvent();
    	}
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new TrioWatchfaceView() ] as [Views];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function getServiceDelegate() {
        inBackground=true;
        System.println("start background");
        return [new TrioBGServiceDelegate()];
    }
}

function getApp() as TrioWatchfaceApp {
    return Application.getApp() as TrioWatchfaceApp;
}