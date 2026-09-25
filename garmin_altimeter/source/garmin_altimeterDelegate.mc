import Toybox.Lang;
import Toybox.WatchUi;

class garmin_altimeterDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new garmin_altimeterMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}