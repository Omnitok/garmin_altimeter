using Toybox.Application.Storage;

class JumpStorage {

    function initialize() {
    }

    function getJumpCount() {
        var storedCount = Storage.getValue("jumpCount");

        if (storedCount == null) {
            return 0;
        }

        return storedCount;
    }

    function saveJump(
        climbSeconds,
        freefallSeconds,
        canopySeconds,
        maximumSpeed
    ) {
        var jumpNumber = getJumpCount() + 1;

        var jump = {
            "number" => jumpNumber,
            "climbSeconds" => climbSeconds,
            "freefallSeconds" => freefallSeconds,
            "canopySeconds" => canopySeconds,
            "maximumSpeed" => maximumSpeed
        };

        var storageKey =
            "jump_" + jumpNumber.format("%d");

        Storage.setValue(storageKey, jump);
        Storage.setValue("jumpCount", jumpNumber);

        return jumpNumber;
    }

    function getJump(jumpNumber) {
        var storageKey =
            "jump_" + jumpNumber.format("%d");

        return Storage.getValue(storageKey);
    }
}