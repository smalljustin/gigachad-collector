class Logger {
    int current_run_starttime;
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
        // print(prevPoint.curGear);
        if (prevPoint != null && curPoint.curGear != prevPoint.curGear) {
            startIdx = isGearChange ? startIdx : idx;
            isGearChange = true;
        }

        @dataPointArray[idx % NUM_POINTS_RECORDED] = curPoint;

        if (isGearChange && idx == startIdx + EXTRA_FRAMES) {
            // flush 
            Json::Value@ outArray = Json::Array();
            for (int i = 0; i < NUM_POINTS_RECORDED; i++) {
                if (dataPointArray[i] != null) {
                    outArray.Add(dataPointArray[i].toJson());
                }
            }
            pendingJsonOut.Add(outArray);
            isGearChange = false;
            print("Gear change!");
        }

        idx += 1;
        @prevPoint = @curPoint;

        handleFileFlush();
        renderHud();
        handleMapAndPlayerCheck();
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
            return current_run_starttime + 1;
        }
        return getPlayer().StartTime;
    }

    bool didPlayerJustRespawn() {
        if (getPlayerStartTime() == current_run_starttime) {
            // Continuing a run. 
            return false;
        } else {
            current_run_starttime = getPlayerStartTime();
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
        nvg::Text(pos, Text::Format("%.2f", Math::ToDeg(curPoint.left_slip)) + "\t\t\t\t\tleft slip");
        pos.y += SPACING;
        nvg::Text(pos, Text::Format("%.2f", Math::ToDeg(curPoint.dir_slip)) + "\t\t\t\t\tdir slip");
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
        nvg::Stroke();
        nvg::ClosePath();

    }
    
}