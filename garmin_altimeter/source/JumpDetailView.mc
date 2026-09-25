using Toybox.Graphics;
using Toybox.WatchUi;
import Toybox.Lang;

class JumpDetailView extends WatchUi.View {

    var storage;
    var jumpNumber;

    function initialize(number) {
        View.initialize();

        storage = new JumpStorage();
        jumpNumber = number;
    }

    function formatDuration(totalSeconds) {
        var minutes = totalSeconds / 60;
        var seconds = totalSeconds % 60;

        return minutes.format("%d")
            + ":"
            + seconds.format("%02d");
    }

    function onUpdate(dc) {
        var centerX = dc.getWidth() / 2;
        var storedJump = storage.getJump(jumpNumber);

        if (storedJump == null) {
            // Existing JUMP NOT FOUND drawing...
            return;
        }

        var jump = storedJump as Dictionary;

        var maximumSpeedKmh =
            jump["maximumSpeed"] * 3.6;
        
        dc.setColor(
            Graphics.COLOR_BLACK,
            Graphics.COLOR_BLACK
        );
        dc.clear();

        if (jump == null) {
            dc.setColor(
                Graphics.COLOR_RED,
                Graphics.COLOR_TRANSPARENT
            );

            dc.drawText(
                centerX,
                105,
                Graphics.FONT_SMALL,
                "JUMP NOT FOUND",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            return;
        }

        dc.setColor(
            Graphics.COLOR_YELLOW,
            Graphics.COLOR_TRANSPARENT
        );

        dc.drawText(
            centerX,
            20,
            Graphics.FONT_MEDIUM,
            "JUMP #" + jumpNumber.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(
            Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );

        dc.drawText(
            centerX,
            65,
            Graphics.FONT_SMALL,
            "CLIMB  "
                + formatDuration(jump["climbSeconds"]),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            98,
            Graphics.FONT_SMALL,
            "FREEFALL  "
                + formatDuration(jump["freefallSeconds"]),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            131,
            Graphics.FONT_SMALL,
            "CANOPY  "
                + formatDuration(jump["canopySeconds"]),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            centerX,
            164,
            Graphics.FONT_SMALL,
            "MAX  "
                + maximumSpeedKmh.format("%.0f")
                + " km/h",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}