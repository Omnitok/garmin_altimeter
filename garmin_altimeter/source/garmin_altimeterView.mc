import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Sensor;
import Toybox.System;
using Toybox.Application.Storage;
using Toybox.Position;
import Toybox.Lang;
using Toybox.ActivityRecording;

class garmin_altimeterView extends WatchUi.View {

    var altitude = 0;
    var groundAltitude = 0;

    var calibrationTotal = 0;
    var calibrationSamples = 0;
    var iscalibrating = true;

    var updateTimer;

    var previousAltitude = null;
    var previousSampleTime = 0;

    var verticalSpeed = 0.0;
    var maximumDescentSpeed = 0.0;
    var maximumAltitude = 0;

    var jumpPhase = :calibrating;

    var climbStartTime = 0;
    var freefallStartTime = 0;
    var canopyStartTime = 0;
    var landingTime = 0;

    var fastDescentSamples = 0;
    var slowDescentSamples = 0;
    var landingCandidateTime = 0;

    // testing
    var useSyntheticTest = false;
    var syntheticStep = 0;

    var hasStarted = false;

    // position
    var gpsTrack = [];
    var gpsRunning = false;
    var lastGpsTimestamp = 0;

    // add FIT session
    var fitSession = null;

    function initialize() {
        View.initialize();
        updateTimer = new Timer.Timer();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function getSyntheticAltitude(step) {
    // Six stationary samples at 100 m MSL.
        if (step < 6) {
            return 100.0;
        }

        // Climb from 100 m to 4100 m MSL.
        if (step <= 45) {
            return 100.0 + ((step - 5) * 110.0);
        }

        // Freefall at 55 m/s.
        if (step <= 100) {
            return 4100.0 - ((step - 45) * 55.0);
        }

        // Canopy descent at 10 m/s.
        if (step <= 195) {
            return 1075.0 - ((step - 100) * 10.0);
        }

        // Stationary at 25 m AGL.
        return 125.0;
    }

    function updateAltitude() as Void {
        var currentMslAltitude = null;
        var now;

        if (useSyntheticTest) {
            currentMslAltitude = getSyntheticAltitude(syntheticStep);
            now = syntheticStep * 1000;
            syntheticStep += 1;
        } else {
            var sensorInfo = Sensor.getInfo();

            if (sensorInfo != null) {
                currentMslAltitude = sensorInfo.altitude;
            }

            now = System.getTimer();
        }

        if (currentMslAltitude == null) {
            WatchUi.requestUpdate();
            return;
        }

//        var now = System.getTimer();

        if (iscalibrating) {
            calibrationTotal += currentMslAltitude;
            calibrationSamples += 1;

            if (calibrationSamples >= 5) {
                groundAltitude = calibrationTotal / calibrationSamples;
                altitude = 0;
                previousAltitude = 0;
                previousSampleTime = now;
                jumpPhase = :ground;
                iscalibrating = false;
            }

            WatchUi.requestUpdate();
            return;
        }

        altitude = currentMslAltitude - groundAltitude;

        // Prevent small negative readings caused by pressure noise.
        if (altitude < 0) {
            altitude = 0;
        }

        if (previousAltitude != null && previousSampleTime != 0) {
            var elapsedSeconds =
                (now - previousSampleTime).toFloat() / 1000.0;

            if (elapsedSeconds > 0) {
                verticalSpeed =
                    (altitude - previousAltitude) / elapsedSeconds;

                updateJumpPhase(now);
            }
        }

        previousAltitude = altitude;
        previousSampleTime = now;

        System.println(
            "step=" + syntheticStep
            + " altitude=" + altitude
            + " speed=" + verticalSpeed
            + " phase=" + getPhaseLabel()
        );

        WatchUi.requestUpdate();
    }

    function updateJumpPhase(now) {
        var descentSpeed = -verticalSpeed;

        if (jumpPhase == :ground) {
            if (altitude > 100 && verticalSpeed > 0.5) {
                jumpPhase = :climbing;
                climbStartTime = now;
                maximumAltitude = altitude;
                maximumDescentSpeed = 0;
                // reset gps track for new jump
                gpsTrack = [];
                lastGpsTimestamp = 0;
            }

            return;
        }

        if (jumpPhase == :climbing) {
            if (altitude > maximumAltitude) {
                maximumAltitude = altitude;
            }

            if (descentSpeed > 20) {
                fastDescentSamples += 1;
            } else {
                fastDescentSamples = 0;
            }

            if (fastDescentSamples >= 2) {
                jumpPhase = :freefall;
                freefallStartTime = now;
                maximumDescentSpeed = descentSpeed;
                slowDescentSamples = 0;

                startFitRecording();

            }

            return;
        }

        if (jumpPhase == :freefall) {
            if (descentSpeed > maximumDescentSpeed) {
                maximumDescentSpeed = descentSpeed;
            }

            if (descentSpeed < 15) {
                slowDescentSamples += 1;
            } else {
                slowDescentSamples = 0;
            }

            if (slowDescentSamples >= 3) {
                jumpPhase = :canopy;
                canopyStartTime = now;
                landingCandidateTime = 0;
            }

            return;
        }

        if (jumpPhase == :canopy) {
            if (altitude < 30 && verticalSpeed > -2 && verticalSpeed < 2) {
                if (landingCandidateTime == 0) {
                    landingCandidateTime = now;
                }

                if (now - landingCandidateTime >= 10000) {
                    jumpPhase = :landed;
                    landingTime = now;
                    saveCompletedJump();
                    stopAndSaveFitRecording();
                }
            } else {
                landingCandidateTime = 0;
            }
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow()  {
        if (!hasStarted) {
            altitude = 0;
            groundAltitude = 0;

            calibrationTotal = 0;
            calibrationSamples = 0;
            iscalibrating = true;

            previousAltitude = null;
            previousSampleTime = 0;

            verticalSpeed = 0.0;
            maximumDescentSpeed = 0.0;
            maximumAltitude = 0;

            jumpPhase = :calibrating;

            climbStartTime = 0;
            freefallStartTime = 0;
            canopyStartTime = 0;
            landingTime = 0;

            fastDescentSamples = 0;
            slowDescentSamples = 0;
            landingCandidateTime = 0;

            syntheticStep = 0;
            hasStarted = true;
        }

        updateTimer.start(
            method(:updateAltitude),
            1000,
            true
        );

        if (!gpsRunning) {
            Position.enableLocationEvents(
                Position.LOCATION_CONTINUOUS,
                method(:onPosition)
            );

            gpsRunning = true;
        }

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

        // Prevent negative displayed values.
        if (displayedAltitude < 0) {
            displayedAltitude = 0;
        }

        // First revolution: 0–4000 m.
        var baseAltitude = displayedAltitude;

        if (baseAltitude > maximumAltitude) {
            baseAltitude = maximumAltitude;
        }

        var baseSweep =
            baseAltitude * 360 / maximumAltitude;

        // Second revolution: 4000–8000 m.
        var extraAltitude =
            displayedAltitude - maximumAltitude;

        if (extraAltitude < 0) {
            extraAltitude = 0;
        }

        if (extraAltitude > maximumAltitude) {
            extraAltitude = maximumAltitude;
        }

        var extraSweep =
            extraAltitude * 360 / maximumAltitude;

        // Determine the normal ring color.
        var ringColor = Graphics.COLOR_GREEN;

        if (displayedAltitude <= 1200) {
            ringColor = Graphics.COLOR_YELLOW;
        }

        if (displayedAltitude < 750) {
            ringColor = Graphics.COLOR_RED;
        }

        // Clear once, before drawing either ring.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Use a wide peripheral ring.
        dc.setPenWidth(50);

        // Draw the first 0–4000 m revolution.
        dc.setColor(ringColor, Graphics.COLOR_BLACK);

        if (baseAltitude >= maximumAltitude) {
            dc.drawCircle(
                centerX,
                centerY,
                radius
            );
        } else if (baseAltitude > 0) {
            dc.drawArc(
                centerX,
                centerY,
                radius,
                Graphics.ARC_CLOCKWISE,
                90,
                90 - baseSweep
            );
        }

        // Draw altitude above 4000 m in blue.
        if (extraAltitude > 0) {
            dc.setColor(
                Graphics.COLOR_BLUE,
                Graphics.COLOR_BLACK
            );

            if (extraAltitude >= maximumAltitude) {
                dc.drawCircle(
                    centerX,
                    centerY,
                    radius
                );
            } else {
                dc.drawArc(
                    centerX,
                    centerY,
                    radius,
                    Graphics.ARC_CLOCKWISE,
                    90,
                    90 - extraSweep
                );
            }
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

        // Jump phase.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY + 38,
            Graphics.FONT_TINY,
            getPhaseLabel(),
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
        updateTimer.stop();
    }

    function getPhaseLabel() {
        if (jumpPhase == :calibrating) {
            return "CALIBRATING";
        } else if (jumpPhase == :ground) {
            return "GROUND";
        } else if (jumpPhase == :climbing) {
            return "CLIMBING";
        } else if (jumpPhase == :freefall) {
            return "FREEFALL";
        } else if (jumpPhase == :canopy) {
            return "CANOPY";
        } else if (jumpPhase == :landed) {
            return "LANDED";
        }

        return "UNKNOWN";
    }

    function saveCompletedJump() {
        var climbSeconds =
            (freefallStartTime - climbStartTime) / 1000;

        var freefallSeconds =
            (canopyStartTime - freefallStartTime) / 1000;

        var canopySeconds =
            (landingTime - canopyStartTime) / 1000;

        var storage = new JumpStorage();

        var jumpNumber = storage.saveJump(
            climbSeconds,
            freefallSeconds,
            canopySeconds,
            maximumDescentSpeed
        );

        System.println(
            "Saved jump #" + jumpNumber
            + " climb=" + climbSeconds
            + " freefall=" + freefallSeconds
            + " canopy=" + canopySeconds
            + " maxSpeed=" + maximumDescentSpeed
        );
    }

    // gps positioning function
        function onPosition(info as Position.Info) as Void {
            if (info.position == null) {
                return;
            }

            if (jumpPhase != :freefall &&
                jumpPhase != :canopy) {
                return;
            }

            var position = info.position;

            if (position == null) {
                return;
            }

            var coordinates = position.toDegrees() as Array;
            var now = System.getTimer();

            if (now == lastGpsTimestamp) {
                return;
            }

            lastGpsTimestamp = now;

            System.println(
                "GPS "
                + coordinates[0]
                + ", "
                + coordinates[1]
                + " phase="
                + getPhaseLabel()
            );
        }

    // add the FIT session
    function startFitRecording() {
        if (fitSession != null) {
            return;
        }

        var storage = new JumpStorage();
        var nextJumpNumber =
            storage.getJumpCount() + 1;

        fitSession = ActivityRecording.createSession({
            :name =>
                "Skydive " + nextJumpNumber.format("%d"),
            :sport =>
                ActivityRecording.SPORT_SKY_DIVING,
            :subSport =>
                ActivityRecording.SUB_SPORT_GENERIC
        });

        if (fitSession != null) {
            fitSession.start();

            System.println(
                "FIT recording started for jump #"
                + nextJumpNumber
            );
        }
    }

    function stopAndSaveFitRecording() {
        if (fitSession == null) {
            return;
        }

        if (fitSession.isRecording()) {
            fitSession.stop();
        }

        fitSession.save();
        fitSession = null;

        System.println("FIT recording saved");
    }

}
