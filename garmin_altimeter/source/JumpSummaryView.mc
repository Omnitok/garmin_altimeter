using Toybox.Graphics;
using Toybox.WatchUi;

class JumpSummaryView extends WatchUi.View {

    var storage;

    function initialize() {
        View.initialize();
        storage = new JumpStorage();
    }

    function onUpdate(dc) {
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var jumpCount = storage.getJumpCount();

        dc.setColor(
            Graphics.COLOR_BLACK,
            Graphics.COLOR_BLACK
        );
        dc.clear();

        dc.setColor(
            Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );

       dc.drawText(
            centerX,
            centerY - 60,
            Graphics.FONT_MEDIUM,
            "Total",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(
            Graphics.COLOR_YELLOW,
            Graphics.COLOR_TRANSPARENT
        );

        dc.drawText(
            centerX,
            centerY - 20,
            Graphics.FONT_NUMBER_HOT,
            jumpCount.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(
            Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_TRANSPARENT
        );

        dc.drawText(
            centerX,
            centerY + 55,
            Graphics.FONT_TINY,
            "press",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}