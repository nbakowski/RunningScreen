import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class RunningScreenView extends WatchUi.DataField {

    hidden var hrValue as Numeric;
    hidden var distanceValue as Numeric;
    hidden var paceValue as String;
    hidden var avgPaceValue as String;
    hidden var elapsedTime as Numeric;
    var hr_value, distance, pace, avg_pace, hrZones, hrColor, current_time, elapsed_time;
    const HR_BORDER_THICKNESS = 7;
    var tiny_text_height;
    var centerX, centerY;


    function initialize() {
        DataField.initialize();
        hrValue = 0;
        distanceValue = 0;
        elapsedTime = 0;
        paceValue = "--:--";
        avgPaceValue = "--:--";
    }

    private function placeDataField(
        id as String, 
        text as String, 
        screenWidth as Number, 
        screenHeight as Number, 
        position as Symbol,
        yOffset as Number
    ) as Void {
        var textElement = View.findDrawableById(id) as Text;
        
        textElement.setText(text);
        
        var x, y;
        
        switch (position) {
            case :TOP_LEFT:
                x = screenWidth / 4;
                y = screenWidth / 4 + yOffset;
                break;
                
            case :TOP_RIGHT:
                x = 3 * screenWidth / 4;
                y = screenWidth / 4 + yOffset;
                break;
                
                
            case :BOTTOM_LEFT:
                x = screenWidth / 4;
                y = screenWidth / 2 + yOffset;
                break;
                
            case :BOTTOM_RIGHT:
                x = 3 * screenWidth / 4;
                y = screenWidth / 2 + yOffset;
                break;

            case :CENTER_TOP:
                x = screenWidth / 2;
                y = tiny_text_height - yOffset;
                break;

            case :CENTER_BOTTOM:
                x = screenWidth / 2;
                y = screenWidth - tiny_text_height - yOffset;
                break;
                
            default:
                x = 10;
                y = 10 + yOffset;
        }
        
        textElement.setLocation(x, y);
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        View.setLayout(Rez.Layouts.MainLayout(dc));
    
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        tiny_text_height = dc.getFontHeight(Graphics.FONT_TINY);

        // Current time
        placeDataField("current_time", "", screenWidth, screenHeight, :CENTER_TOP, 25);
        current_time = View.findDrawableById("current_time") as Text;
        
        // HR
        placeDataField("hr_label", "HR", screenWidth, screenHeight, :TOP_LEFT, -20);
        placeDataField("hr_value", "", screenWidth, screenHeight, :TOP_LEFT, 20);
        hr_value = View.findDrawableById("hr_value") as Text;
        hrZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC) as Array<Number>;

        // Dist
        placeDataField("dist_label", "DIST", screenWidth, screenHeight, :TOP_RIGHT, -20);
        placeDataField("dist_value", "", screenWidth, screenHeight, :TOP_RIGHT, 20);
        distance = View.findDrawableById("dist_value") as Text;

        // Pace
        placeDataField("pace_label", "PACE", screenWidth, screenHeight, :BOTTOM_LEFT, 20);
        placeDataField("pace_value", "", screenWidth, screenHeight, :BOTTOM_LEFT, 60);
        pace = View.findDrawableById("pace_value") as Text;

        // Average pace
        placeDataField("avg_pace_label", "AVG. PACE", screenWidth, screenHeight, :BOTTOM_RIGHT, 20);
        placeDataField("avg_pace_value", "", screenWidth, screenHeight, :BOTTOM_RIGHT, 60);
        avg_pace = View.findDrawableById("avg_pace_value") as Text;

        // Elapsed time
        placeDataField("elapsed_time", "", screenWidth, screenHeight, :CENTER_BOTTOM, 20);
        elapsed_time = View.findDrawableById("elapsed_time") as Text;

        centerX = dc.getWidth() / 2;
        centerY = dc.getHeight() / 2;

    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
        if (info has :currentHeartRate) {
            if (info.currentHeartRate != null ){
                hrValue = info.currentHeartRate as Number;
            } else {
                hrValue = 0.0f;
            }
        }

        if (info has :elapsedDistance) {
            if (info.elapsedDistance != null) {
                distanceValue = info.elapsedDistance as Number;
            } else {
                distanceValue = 0.0f;
            }
        }
        if (info has :currentSpeed) {
            if (info.currentSpeed != null) {
                var rawPace = getPaceFromSpeed(info.currentSpeed as Float);
                paceValue = formatPace(rawPace);
            } else {
                paceValue = "--:--";
            }
        }
        if (info has :averageSpeed) {
            if (info.elapsedTime != null) {
                var rawPace = getPaceFromSpeed(info.averageSpeed as Float);
                avgPaceValue = formatPace(rawPace);
            } else {
                paceValue = "--:--";
            }
        }
        if (info has :elapsedTime) {
            if (info.elapsedTime != null) {
                elapsedTime = info.elapsedTime as Number;
            } else {
                elapsedTime = 0.0f;
            }
        }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Display current time
        drawTime();

        // Display workout data
        displayData();

        View.onUpdate(dc);

        // Display HR zones indicator
        drawHearRateIndicator(dc);

        // Draw borders
        drawBorders(dc);
        
    }

    private function drawTime() as Void {
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();;
        var timeString = Lang.format(timeFormat, [clockTime.hour, clockTime.min.format("%02d")]);
        current_time.setText(timeString);
    }

    private function displayData() {
        hr_value.setText(hrValue != null ? hrValue.format("%d") : "--");
        distance.setText(formatDistance(distanceValue));
        pace.setText(paceValue);
        avg_pace.setText(avgPaceValue);
        elapsed_time.setText(formatTime(elapsedTime));
    }

    private function drawHearRateIndicator(dc as Dc) as Void {
        hrColor = getHRColor(hrValue, hrZones);
        dc.setColor(hrColor, hrColor);
        dc.setPenWidth(14);
        dc.drawArc(centerX, centerY, centerX, Graphics.ARC_CLOCKWISE, 180, 140); // Left part of the box
        dc.setPenWidth(HR_BORDER_THICKNESS);
        dc.drawLine(0, HR_BORDER_THICKNESS + dc.getHeight() / 6, centerX, HR_BORDER_THICKNESS + dc.getHeight() / 6); // Top part of the box
        dc.drawLine(centerX - HR_BORDER_THICKNESS, centerY, centerX - HR_BORDER_THICKNESS, dc.getHeight() / 6); // Right part of the box
        dc.drawLine(0, centerY - HR_BORDER_THICKNESS, centerX, centerY - HR_BORDER_THICKNESS); // Bottom part of the box
    }

    private function drawBorders(dc as Dc) as Void {
        dc.setPenWidth(7);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX, dc.getHeight() - dc.getHeight() / 6, centerX, dc.getHeight() / 6); // Middle line
        dc.drawLine(0, dc.getHeight() / 6, dc.getWidth(), dc.getHeight() / 6); // Top line
        dc.drawLine(0, dc.getHeight() - dc.getHeight() / 6, dc.getWidth(), dc.getHeight() - dc.getHeight() / 6); // Bottom line
        dc.drawLine(0, centerY, dc.getWidth(), centerY); // Horizontal middle line
    }

    // Get HR zone color
    private function getHRColor(currentHR as Number, hrZones as Array<Number>) {
        if (currentHR == null || hrZones == null) {
            return Graphics.COLOR_WHITE;
        }
        if (currentHR <= hrZones[1]) {
            return Graphics.COLOR_LT_GRAY;   // Zone 1
        } else if (currentHR <= hrZones[2]) {
            return Graphics.COLOR_BLUE;      // Zone 2
        } else if (currentHR <= hrZones[3]) {
            return Graphics.COLOR_GREEN;     // Zone 3
        } else if (currentHR <= hrZones[4]) {
            return Graphics.COLOR_ORANGE;    // Zone 4
        } else {
            return Graphics.COLOR_RED;       // Zone 5
        }
    }

    // Converts a decimal pace (e.g., 5.5) to a string (e.g., "5:30")
    private function formatPace(pace as Float) as String {
        if (pace <= 0) {
            return "--:--";
        }

        var minutes = pace.toNumber();
        var seconds = ((pace - minutes) * 60).toNumber();

        return minutes.format("%d") + ":" + seconds.format("%02d");
    }

    private function formatTime(time as Float) as String {
        if (time <= 0) {
            return "--:--";
        }

        time = time / 1000;

        var totalSeconds = time.toNumber();
        var minutes = totalSeconds / 60;
        var seconds = totalSeconds % 60;

        return minutes.format("%d") + ":" + seconds.format("%02d");
    }

    // Converts speed (m/s) to pace (minutes per kilometer)
    private function getPaceFromSpeed(speed as Float) as Float {

        var settings = System.getDeviceSettings();

        if (speed != null && speed > 0.2) { 
            if (settings.distanceUnits == System.UNIT_METRIC) {
                return 1000 / (60 * speed);
            } else {
                return 26.8224 / speed;
            }
        }
        return 0.0f;
    }

    private function formatDistance(meters) {
        var settings = System.getDeviceSettings();
        
        if (settings.distanceUnits == System.UNIT_METRIC) {
            if (meters > 10000) {
                return (meters / 1000.0).format("%.1f") + " km";
            }
            return (meters / 1000.0).format("%.2f") + " km";
        } else {
            if (meters > 10000) {
                return (meters / 1609.34).format("%.1f") + " mi";
            }
            return (meters / 1609.34).format("%.2f") + " mi";
        }
    }

    private function setColors(id as String, backgroundColor as ColorValue) as Void {
        var element = View.findDrawableById(id) as Text;
        if (backgroundColor == Graphics.COLOR_BLACK || backgroundColor == Graphics.COLOR_TRANSPARENT) {
            element.setColor(Graphics.COLOR_WHITE);
        } else {
            element.setColor(Graphics.COLOR_BLACK);
        }
    }

}