/* globals */

string activeRespawnId;
string activeRunId;

class Logger {
    int currentRunStartTime;
    Json::Value@ pendingJsonOut = Json::Array();
    array<DataPoint@> dataPointArray(5000);

    Logger () {}
    bool kill = false;
    
    DataPoint@ prevPoint;
    DataPoint@ curPoint;
    
    int idx = 0; 
    int startIdx = 0;
    bool isGearChange = false;

    void handleMapAndPlayerCheck() {
        string curMapUuid = getMapUid();
        if (curMapUuid == "") {
            enabled = false;
        }
    }

    void logAndRender() {
        if (!enabled) {
            return;
        }


        @curPoint = DataPoint(getVisState());
        renderHud();

        if (DISABLE_NETWORK) {
            return;
        }

        if (curPoint.velocity.LengthSquared() < 1) {
            return;
        }

        // print(prevPoint.curGear);
        if (prevPoint != null && curPoint.curGear != prevPoint.curGear) {
            startIdx = isGearChange ? startIdx : idx;
            isGearChange = true;
            activeRunId = Crypto::RandomBase64(32);
        }

        @dataPointArray[idx % NUM_POINTS_RECORDED] = curPoint;

        if (isGearChange && idx == startIdx + EXTRA_FRAMES) {
            // flush 
            Json::Value@ outArray = Json::Array();
            int pidx = idx % NUM_POINTS_RECORDED;
            for (int i = 0; i < NUM_POINTS_RECORDED; i++) {
                if (dataPointArray[pidx] != null) {
                    dataPointArray[pidx].pidx = i - EXTRA_FRAMES;
                    outArray.Add(dataPointArray[pidx].toJson());
                }
                pidx = (pidx + NUM_POINTS_RECORDED - 1) % NUM_POINTS_RECORDED;
            }
            pendingJsonOut.Add(outArray);
            isGearChange = false;
            print("Gear change!");
        }

        idx += 1;
        @prevPoint = @curPoint;

        printLength();
        handleNetworkFlush();
        handleMapAndPlayerCheck();
    }

    void printLength() {
        int count = 0; 
        for (int i = 0; i < pendingJsonOut.Length; i++) {
            count += pendingJsonOut[i].Length;
        }
    }
    void handleFileFlush() {
        if (didPlayerJustRespawn() && pendingJsonOut.Length > 0) {
            string filename = "gcc_out_" + Time::get_Now() + ".json";
            string path = IO::FromStorageFolder(filename);
            print("Writing to file " + path);
            Json::ToFile(path, pendingJsonOut);
            pendingJsonOut = Json::Array();
        }
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
        nvg::Stroke();
        nvg::ClosePath();

    }
    
}