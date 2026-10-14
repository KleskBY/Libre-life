package by.quake.zircon;

/** ObjectN: data is bundled in the APK, no mod browser, no storage permission. */
final class FlavorProfile extends GameProfile {

    @Override
    public DataMode dataMode() {
        return DataMode.BUNDLED_PK3;
    }

    @Override
    public String baseGameDir() {
        return "data";
    }

    @Override
    public String baseGameTitle() {
        return "ObjectN";
    }

    @Override
    public String defaultLayoutAsset() {
        return "controls/objectn.json";
    }

    @Override
    public int accentColor() {
        return 0xFFE53935; // logo red
    }

    @Override
    public String bundledPack() {
        return "objectn.pk3";
    }

    @Override
    public String builtinCfg() {
        return "android.cfg";
    }
}
