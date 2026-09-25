import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Sensor;

class garmin_altimeterView extends WatchUi.View {

    var altitude = 0;
    var groundAltitude = 0;

    var calibrationTotal = 0;
    var calibrationSamples = 0;
    var iscalibrating = true;

    var updateTimer;

    function initialize() {
        View.initialize();
        updateTimer = new Timer.Timer();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function updateAltitude() as Void {
        var sensorInfo = Sensor.getInfo();

        if (sensorInfo == null) {
            WatchUi.requestUpdate();
            return;
        }

        var currentAltitude = sensorInfo.altitude;

        if (iscalibrating) {
            calibrationTotal += currentAltitude;
            calibrationSamples += 1;
        }

        // 5 reading average for calibration
        if (calibrationSamples >= 5) {
            groundAltitude = calibrationTotal / calibrationSamples;
            altitude = 0;
            iscalibrating = false;
            } 
        else {
            altitude = (currentAltitude - groundAltitude).toNumber();
        }

        WatchUi.requestUpdate();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow()  {
        altitude = 0;
        groundAltitude = 0;

        calibrationTotal = 0;
        calibrationSamples = 0;
        iscalibrating = true;

        updateTimer.start(method(:updateAltitude), 1000, true);
    }

    // Update the view
    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        var centerX = width / 2;
        var centerY = height / 2;

        if (iscalibrating) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();

            dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY - 30,
                Graphics.FONT_MEDIUM,
                "CALIBRATING",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + 10,
                Graphics.FONT_SMALL,
                calibrationSamples.format("%d") + " / 5",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            return;
        }

        // Leave enough space so the wider ring is not clipped.
        var radius = width / 2 - 15;
        var maximumAltitude = 4000;
        var displayedAltitude = altitude;

        if (displayedAltitude < 0) {
            displayedAltitude = 0;
        }

        if (displayedAltitude > maximumAltitude) {
            displayedAltitude = maximumAltitude;
        }

        var sweep = displayedAltitude * 360 / maximumAltitude;
        var ringColor = Graphics.COLOR_GREEN;

        // 750–1200 m: orange
        if (displayedAltitude <= 1200) {
            ringColor = Graphics.COLOR_YELLOW;
        }

        // Below 750 m: red
        if (displayedAltitude < 750) {
            ringColor = Graphics.COLOR_RED;
        }

        // Clear the screen.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Wider peripheral ring.
        dc.setPenWidth(50);

        // Empty part of the scale.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawCircle(centerX, centerY, radius);

        // Remaining altitude.
        dc.setColor(ringColor, Graphics.COLOR_BLACK);

        if (displayedAltitude >= maximumAltitude) {
            dc.drawCircle(centerX, centerY, radius);
        } else if (displayedAltitude > 0) {
            dc.drawArc(
                centerX,
                centerY,
                radius,
                Graphics.ARC_CLOCKWISE,
                90,
                90 - sweep
            );
        }

        // Numerical altitude.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY - 30,
            Graphics.FONT_NUMBER_HOT,
            displayedAltitude.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER
        );

//        dc.drawText(
//           centerX,
//            centerY + 15,
//            Graphics.FONT_SMALL,
//            "m AGL",
//            Graphics.TEXT_JUSTIFY_CENTER
//        );

//        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
//        dc.drawText(
//            centerX,
//            centerY + 43,
//            Graphics.FONT_TINY,
//            "SIMULATION",
//            Graphics.TEXT_JUSTIFY_CENTER
//        );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
        updateTimer.stop();
    }

}
