class RunKey {
    int rkId;
    string name;
    int mode;

    RunKey() {}
    RunKey(int in_rkId, string in_name, int in_mode) {
        rkId = in_rkId;
        name = in_name;
        mode = in_mode;
    }
}

class MapTag {
    int mtId;
    string mapUuid;
    string tag;
    string username;

    MapTag() {}
    MapTag(int in_mtId, string in_mapUuid, string in_tag, string in_username) {
        mtId = in_mtId;
        mapUuid = in_mapUuid;
        tag = in_tag;
        username = in_username;
    }
}