/* globals */

string activeRespawnId;
string activeRunId;
string activeMapUuid;
array<string> valid_runkeys;
string new_runkeyname; 
string query_runkey;
int new_runkeymode = 1;

array<RunKey> loaded_runkeys;
RunKey active_runkey;
bool loadingRunkeys = false;

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

class Logger {
    int currentRunStartTime;
    Json::Value@ pendingJsonOut = Json::Array();
    array<DataPoint@> dataPointArray(5500);

    Logger () {}
    bool kill = false;
    
    DataPoint@ prevPoint;
    DataPoint@ curPoint;
    
    int idx = 0; 
    int startIdx = 0;
    bool isGearChange = false;

    void handleMapAndPlayerCheck() {
        string curMapUuid = getMapUid();
        if (curMapUuid == "" || curMapUuid != activeMapUuid) {
            enabled = false;
            activeMapUuid = curMapUuid;
        }
    }

    void handleMode1() {
        if (active_runkey.mode != 1) {
            return;
        }
        if (idx % T1_NUM_POINTS_RECORDED == 0) {
            print("Snipping!");
            int pidx = idx % T1_NUM_POINTS_RECORDED;
            Json::Value@ outArray = Json::Array();
            for (int i = 0; i < T1_NUM_POINTS_RECORDED; i++) {
                if (dataPointArray[pidx] != null) {
                    dataPointArray[pidx].pidx = i;
                    outArray.Add(dataPointArray[pidx].toJson());
                }
                pidx = (pidx + 1) % T1_NUM_POINTS_RECORDED;
            }
            pendingJsonOut.Add(outArray);
        }
        idx = (idx + 1) % T1_NUM_POINTS_RECORDED;


    }

    void handleMode2() {
        if (active_runkey.mode != 2) {
            return;
        }

        if (prevPoint != null && curPoint.curGear != prevPoint.curGear && !isGearChange) {
            startIdx = isGearChange ? startIdx : idx;
            isGearChange = true;
            activeRunId = Crypto::RandomBase64(32);
        }

        if (isGearChange && idx == startIdx + T2_EXTRA_FRAMES) {
            // flush 
            Json::Value@ outArray = Json::Array();
            int pidx = idx % T2_NUM_POINTS_RECORDED;
            for (int i = 0; i < T2_NUM_POINTS_RECORDED; i++) {
                if (dataPointArray[pidx] != null) {
                    dataPointArray[pidx].pidx = i - T2_EXTRA_FRAMES;
                    outArray.Add(dataPointArray[pidx].toJson());
                }
                pidx = (pidx + T2_NUM_POINTS_RECORDED - 1) % T2_NUM_POINTS_RECORDED;
            }
            pendingJsonOut.Add(outArray);
            isGearChange = false;
            print("Gear change!");
        }
        idx = (idx + 1) % T2_NUM_POINTS_RECORDED;
    }

    void logAndRender() {
        handleMapAndPlayerCheck();
        renderRunkeyManagerHud();

        if (!enabled) {
            return;
        }

        @curPoint = DataPoint(getVisState());
        renderHud();

        if (curPoint.velocity.LengthSquared() < 1) {
            return;
        }

        @dataPointArray[idx] = curPoint;

        handleMode1();
        handleMode2();

        @prevPoint = @curPoint;

        handleNetworkFlush();
    }

    void handleNetworkFlush() {
        if (didPlayerJustRespawn() && pendingJsonOut.Length > 0) {
            startnew(CoroutineFunc(this.submitData));
        }
    }

    void submitData() {
        string url = url_base + "datapoint";
        print("Serlizing and pushing! Current time: " + tostring(Time::get_Now()));
        
        Json::Value@ out_obj = Json::Object();
        out_obj["data"] = pendingJsonOut;
        out_obj["token"] = token_uuid;
        out_obj["rkId"] = active_runkey.rkId;

        string data = Json::Write(out_obj);
        print("Serlized! Current time: " + tostring(Time::get_Now()) + "\t Length: " + tostring(data.Length));
        pendingJsonOut = Json::Array();

        Net::HttpRequest@ request = Net::HttpPost(url, data, "application/json");
        while (!request.Finished()) {
            yield();
        }

        if (request.ResponseCode() == 200) {
            print("Pushed! Current time: " + tostring(Time::get_Now()));
            pendingJsonOut = Json::Array();
        } else {
            Authenticate();
            submitData();
        }

    }

    CSmArenaClient@ getPlayground() {
        return cast < CSmArenaClient > (GetApp().CurrentPlayground);
    }

    CSmPlayer@ getPlayer() {
        auto playground = getPlayground();
        if (playground!is null) {
            if (playground.GameTerminals.Length > 0) {
                CGameTerminal @ terminal = cast < CGameTerminal > (playground.GameTerminals[0]);
                CSmPlayer @ player = cast < CSmPlayer > (terminal.GUIPlayer);
                if (player!is null) {
                    return player;
                }   
            }
        }
        return null;
    }

    int getPlayerStartTime() {
        if (getPlayer() is null) {
            return currentRunStartTime + 1;
        }
        return getPlayer().StartTime;
    }

    bool didPlayerJustRespawn() {
        if (getPlayerStartTime() == currentRunStartTime) {
            // Continuing a run. 
            return false;
        } else {
            currentRunStartTime = getPlayerStartTime();
            activeRespawnId = Crypto::RandomBase64(32);
            return true;
        }
    }

    void renderHud() {
        nvg::BeginPath();
        nvg::RoundedRect(graph_x_offset, graph_y_offset, graph_width, graph_height, BorderRadius);
        nvg::FillColor(BackdropColor);
        nvg::Fill();
        nvg::StrokeColor(BorderColor);
        nvg::StrokeWidth(BorderWidth);
        nvg::Stroke();

        vec2 pos = vec2(graph_x_offset + SPACING, graph_y_offset + SPACING);

        nvg::BeginPath();
        nvg::FillColor(vec4(.9, .9, .9, 1));
        nvg::Text(pos, tostring(curPoint.curGear) + "\t\t\t\t\tgear");
        pos.y += SPACING;
        nvg::Text(pos, Text::Format("%.2f", RADIANS ? curPoint.left_slip : Math::ToDeg(curPoint.left_slip)) + "\t\t\t\t\tleft slip");
        pos.y += SPACING;
        nvg::Text(pos, Text::Format("%.2f", RADIANS ? curPoint.dir_slip : Math::ToDeg(curPoint.dir_slip)) + "\t\t\t\t\tdir slip");
        pos.y += SPACING;
        nvg::Text(pos, Text::Format("%.2f", curPoint.frontspeed) + "\t\t\t\t\tfrontspeed");
        pos.y += SPACING;
        nvg::Text(pos, Text::Format("%.2f", curPoint.velocity.Length()) + "\t\t\t\t\tvelocity");
        pos.y += SPACING;
        nvg::Text(pos,
            Text::Format("%.3f", curPoint.flDamperLen * 100) + ", " + 
            Text::Format("%.3f", curPoint.frDamperLen * 100) + ", " + 
            Text::Format("%.3f", curPoint.rlDamperLen * 100) + ", " + 
            Text::Format("%.3f", curPoint.frDamperLen * 100) + "\t\t\t\t\tsuspension");
        pos.y += SPACING;
        nvg::Text(pos, tostring(Time::get_Now()) + "\t\t\t\t\tcurrent time");
        pos.y += SPACING;
        nvg::Text(pos, Text::Format("%.3f", curPoint.p_dt) + "\t\t\t\t\tcurrent dt");
        pos.y += SPACING;
        nvg::Text(pos, tostring(curPoint.inputBrake) + "\t\t\t\t\tbraking");
        pos.y += SPACING;
        nvg::Text(pos, tostring(curPoint.p_activeRunId));
        nvg::Stroke();
        nvg::ClosePath();

    }

    void getActiveRunKeys() {
        startnew(CoroutineFunc(this._getActiveRunKeys));
    }

    void _getActiveRunKeys() {
        while (token_uuid == "" || token_uuid == "ERROR") {
            yield();
        }
        if (loadingRunkeys) {
            return;
        }

        loadingRunkeys = true;
        string url = url_base + "runkey?token=" + token_uuid;
        print("Fetching runkeys at url: " + url);
        Net::HttpRequest@ request = Net::HttpGet(url);
        while (!request.Finished()) {
            yield();
        }
        if (request.ResponseCode() == 200) {
            Json::Value@ obj = Json::Parse(request.String());
            loaded_runkeys = array<RunKey>();
            for (int i = 0; i < obj.Length; i++) {
                loaded_runkeys.InsertLast(RunKey(obj[i]["rkId"], obj[i]["name"], obj[i]["mode"]));
            }
        }
        loadingRunkeys = false;
    }

    void findMatchingRunKey() {
        for (int i = 0; i < loaded_runkeys.Length; i++) {
            if (loaded_runkeys[i].name.Trim().ToLower() == query_runkey.Trim().ToLower()) {
                active_runkey = loaded_runkeys[i];
                return;
            }
        }
    }

    void saveNewRunKey() {
        startnew(CoroutineFunc(this._saveNewRunKey));
    }

    void _saveNewRunKey() {
        if (new_runkeyname.Length < 3) {
            new_runkeyname = "";
            return;
        }
        getActiveRunKeys();

        for (int i = 0; i < loaded_runkeys.Length; i++) {
            if (loaded_runkeys[i].name.Trim().ToLower() == new_runkeyname.Trim().ToLower()) {
                active_runkey = loaded_runkeys[i];
                return;
            }
        }

        string url = url_base + "runkey";
        Json::Value@ out_obj = Json::Object();
        out_obj["token"] = token_uuid;
        Json::Value@ new_runkey = Json::Object();
        new_runkey["name"] = new_runkeyname;
        new_runkey["mode"] = new_runkeymode;
        out_obj["runKey"] = new_runkey;

        string data = Json::Write(out_obj);
        print("data: " + data);
        Net::HttpRequest@ request = Net::HttpPost(url, data, "application/json");
        while (!request.Finished()) {
            yield();
        }
        this.getActiveRunKeys();
    }

    
    
    void renderRunkeyManagerHud() {
        if (SHOW_RUNKEY_MANAGER) {
            if (token_uuid == "" || token_uuid == "ERROR") {
                UI::Begin("Configure run keys");
                UI::Text("Please wait, waiting for authentication.");
                UI::End();
                return;
            }

            if (loaded_runkeys.Length == 0) {
                getActiveRunKeys();
            }

            UI::Begin("Configure run keys", UI::WindowFlags::AlwaysAutoResize);
                            if (UI::Button("Refresh loaded runkeys")) {
                    this.getActiveRunKeys();
                }
                if (active_runkey.rkId == 0) {
                    UI::Text("Please select a run key");
                } else {
                    UI::Text("Active runkey: " + active_runkey.name + ", mode: " + active_runkey.mode + " (id: " + active_runkey.rkId + ")");
                    if (UI::Button("Start/stop recording", vec2(200, 30))) {
                    enabled = !enabled;
                };
                }

                query_runkey = UI::InputText("Find an existing key", query_runkey);
                if (UI::Button("Find existing key", vec2(200, 30))) {
                    this.findMatchingRunKey();
                };

                UI::Text("Create a new run key:");
                UI::Text("Values for 'mode':");
                UI::Text("1: 'snip' on respawn (default)");
                UI::Text("2: 'snip' on gear change (default)");

                new_runkeyname = UI::InputText("New run key name", new_runkeyname);
                if (UI::Button("Set run key", vec2(200, 30))) {
                    this.saveNewRunKey();
                };
                new_runkeymode = UI::InputInt("New run key mode", new_runkeymode);

                if (UI::Button("Create new run key", vec2(200, 30))) {
                    this.saveNewRunKey();
                };



                for (int i = 0; i < loaded_runkeys.Length; i++) {
                     UI::Text(loaded_runkeys[i].name);
                }
                // if (UI::Button("Save", vec2(200, 30))) {
                //     databasefunctions.removeAllCustomTimeTargets(active_map_uuid);
                //     doCustomTimeTargetRefresh();
                // };


            UI::End();
        }
    }
}