package by.quake.zircon;


/** Libre-life: the player copies the game data folder to shared storage, same as the Quake flavor. */
final class FlavorProfile extends GameProfile {

    @Override
    public DataMode dataMode() {
        return DataMode.EXTERNAL_DIR;
    }

    @Override
    public String baseGameDir() {
        return "data";
    }

    @Override
    public String baseGameTitle() {
        return "Libre-life";
    }

    @Override
    public String defaultLayoutAsset() {
        return "controls/librelife.json";
    }

    @Override
    public String defaultsCfgAsset() {
        return "mobile_defaults.cfg";
    }

    @Override
    public int accentColor() {
        return 0xFF4FA3C7; // Libre-life blue
    }

}
