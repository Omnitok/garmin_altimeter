using Toybox.WatchUi;

class JumpListDelegate extends WatchUi.BehaviorDelegate {

    var listView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        listView = view;
    }

    // Down selects an older jump.
    function onNextPage() {
        listView.selectOlder();
        return true;
    }

    // Up selects a newer jump.
    function onPreviousPage() {
        listView.selectNewer();
        return true;
    }

    // Upper-right button opens the selected jump.
    function onSelect() {
        var jumpNumber =
            listView.getSelectedJumpNumber();

        if (jumpNumber < 1) {
            return true;
        }

        var detailView =
            new JumpDetailView(jumpNumber);

        WatchUi.pushView(
            detailView,
            new JumpDetailDelegate(),
            WatchUi.SLIDE_UP
        );

        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}