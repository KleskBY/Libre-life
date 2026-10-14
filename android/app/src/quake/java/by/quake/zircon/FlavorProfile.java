package by.quake.zircon;


/** Quake: player-supplied id1 and mods in shared storage, same folder layout as other Android Quake ports. */
final class FlavorProfile extends GameProfile {

    @Override
    public DataMode dataMode() {
        return DataMode.EXTERNAL_DIR;
    }

    @Override
    public String baseGameDir() {
        return "id1";
    }

    @Override
    public String baseGameTitle() {
        return "Quake";
    }

    @Override
    public String dataHint() {
        return "Copy PAK0.PAK and PAK1.PAK from your Quake installation into";
    }

    @Override
    public String defaultLayoutAsset() {
        return "controls/quake.json";
    }

    @Override
    public String defaultsCfgAsset() {
        return "mobile_defaults.cfg";
    }

}
