using Toybox.Graphics;
using Toybox.WatchUi;

class JumpListView extends WatchUi.View {

    var storage;
    var selectedJumpNumber = 0;

    function initialize() {
        View.initialize();

        storage = new JumpStorage();
        selectedJumpNumber = storage.getJumpCount();
    }

    function selectOlder() {
        if (selectedJumpNumber > 1) {
            selectedJumpNumber -= 1;
            WatchUi.requestUpdate();
        }
    }

    function selectNewer() {
        var count = storage.getJumpCount();

        if (selectedJumpNumber < count) {
            selectedJumpNumber += 1;
            WatchUi.requestUpdate();
        }
    }

    function getSelectedJumpNumber() {
        return selectedJumpNumber;
    }

    function onUpdate(dc) {
        var centerX = dc.getWidth() / 2;
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

//        dc.drawText(
//            centerX,
//            10,
//            Graphics.FONT_MEDIUM,
//            "JUMPS",
//            Graphics.TEXT_JUSTIFY_CENTER
//        );

        if (jumpCount == 0) {
            dc.drawText(
                centerX,
                105,
                Graphics.FONT_SMALL,
                "NO SAVED JUMPS",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            return;
        }

        var firstJump = selectedJumpNumber + 2;

        if (firstJump > jumpCount) {
            firstJump = jumpCount;
        }

        var y = 52;

        for (var row = 0; row < 5; row += 1) {
            var jumpNumber = firstJump - row;

            if (jumpNumber < 1) {
                break;
            }

            if (jumpNumber == selectedJumpNumber) {
                dc.setColor(
                    Graphics.COLOR_YELLOW,
                    Graphics.COLOR_TRANSPARENT
                );
            } else {
                dc.setColor(
                    Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT
                );
            }

            var marker = "  ";

            if (jumpNumber == selectedJumpNumber) {
                marker = "> ";
            }

            dc.drawText(
                centerX,
                y,
                Graphics.FONT_SMALL,
                marker + "JUMP #" + jumpNumber.format("%d"),
                Graphics.TEXT_JUSTIFY_CENTER
            );

            y += 32;
        }
    }
}