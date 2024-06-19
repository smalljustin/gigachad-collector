class DataPoint {
    int version = 4;

    DataPoint() {}

    int pidx;
    
    vec3 position; 
    vec3 velocity;
    float frontspeed;

    float inputSteer; 
    bool inputBrake;
    float inputGas;
    
    float flDamperLen; 
    float frDamperLen;
    float rlDamperLen;
    float rrDamperLen;

    vec3 vec_vel;
    vec3 vec_dir; 
    vec3 vec_left; 
    vec3 vec_up;

    float dir_slip;
    float left_slip;

    uint curGear;
    uint64 time;
    float p_dt;
    string p_activeRespawnId;
    string p_activeRunId;

    EPlugSurfaceMaterialId flGroundContactMaterial;
    EPlugSurfaceMaterialId frGroundContactMaterial;
    EPlugSurfaceMaterialId rlGroundContactMaterial;
    EPlugSurfaceMaterialId rrGroundContactMaterial;
    ESceneVehicleVisReactorBoostType reactor;

    DataPoint(CSceneVehicleVisState@ visState) {
        if (visState is null) {
            return;
        }
        position = visState.Position;
        velocity = visState.WorldVel;
        curGear = visState.CurGear;

        frontspeed = visState.FrontSpeed;
        
        inputSteer = visState.InputSteer;
        inputBrake = visState.InputIsBraking;
        inputGas = visState.InputGasPedal;

        flDamperLen = visState.FLDamperLen;
        frDamperLen = visState.FRDamperLen;
        rlDamperLen = visState.RLDamperLen;
        rrDamperLen = visState.RRDamperLen;

        vec_vel = visState.WorldVel;
        vec_dir = visState.Dir;
        vec_left = visState.Left;
        vec_up = visState.Up;

        flGroundContactMaterial = visState.FLGroundContactMaterial;
        frGroundContactMaterial = visState.FRGroundContactMaterial;
        rlGroundContactMaterial = visState.RLGroundContactMaterial;
        rrGroundContactMaterial = visState.RRGroundContactMaterial; 
        reactor = visState.ReactorBoostType;

        vec3 v = visState.WorldVel.Normalized();
        dir_slip = Math::Angle(visState.Dir, v);
        left_slip = Math::Angle(visState.Left, v);
        time = Time::get_Now();
        p_dt = g_dt;
        p_activeRespawnId = activeRespawnId;
        p_activeRunId = activeRunId;
    }

    float pp(float v) {
        if (Math::IsNaN(v) || Math::IsNaN(-v) || Math::IsInf(v) || Math::IsInf(-v)) {
            return -100;
        } return v;
    }

    Json::Value@ toJson() {
        vec3 vel_norm = velocity.Normalized();
        Json::Value@ json = Json::Object();
        json["pidx"] = pidx;
        json["version"] = version;
        json["position"] = tostring(position);
        json["velocity"] = tostring(velocity);
        json["speed"] = velocity.Length();
        json["frontSpeed"] = frontspeed;
        json["inputSteer"] = inputSteer;
        json["inputBrake"] = inputBrake;
        json["inputGas"] = inputGas;
        json["flDamperLen"] = flDamperLen;
        json["frDamperLen"] = frDamperLen;
        json["rlDamperLen"] = rlDamperLen;
        json["rrDamperLen"] = rrDamperLen;
        json["vecVel"] = tostring(vec_vel);
        json["vecDir"] = tostring(vec_dir);
        json["vecLeft"] = tostring(vec_left);
        json["vecUp"] = tostring(vec_up);
        json["slipDir"] = pp(dir_slip);
        json["slipLeft"] = pp(left_slip);
        json["curGear"] = curGear;
        json["flGroundContactMaterial"] = tostring(flGroundContactMaterial);
        json["frGroundContactMaterial"] = tostring(frGroundContactMaterial);
        json["rlGroundContactMaterial"] = tostring(rlGroundContactMaterial);
        json["rrGroundContactMaterial"] = tostring(rrGroundContactMaterial);
        json["reactor"] = reactor;
        json["time"] = Text::Format("%d", time);
        json["dt"] = p_dt;
        json["runId"] = p_activeRunId;
        json["respawnId"] = p_activeRespawnId;

        return json;
    }
    
}