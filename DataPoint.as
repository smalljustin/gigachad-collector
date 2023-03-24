class DataPoint {
    int version = 1;

    DataPoint() {}
    
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
    }

    Json::Value@ toJson() {
        Json::Value@ json = Json::Object();
        json["version"] = version;
        json["position"] = tostring(position);
        json["velocity"] = tostring(velocity);
        json["frontspeed"] = frontspeed;
        json["inputSteer"] = inputSteer;
        json["inputBrake"] = inputBrake;
        json["inputGas"] = inputGas;
        json["flDamperLen"] = flDamperLen;
        json["frDamperLen"] = frDamperLen;
        json["rlDamperLen"] = rlDamperLen;
        json["rrDamperLen"] = rrDamperLen;
        json["vec_vel"] = tostring(vec_vel);
        json["vec_dir"] = tostring(vec_dir);
        json["vec_left"] = tostring(vec_left);
        json["vec_up"] = tostring(vec_up);
        json["curGear"] = curGear;
        json["flGroundContactMaterial"] = tostring(flGroundContactMaterial);
        json["frGroundContactMaterial"] = tostring(frGroundContactMaterial);
        json["rlGroundContactMaterial"] = tostring(rlGroundContactMaterial);
        json["rrGroundContactMaterial"] = tostring(rrGroundContactMaterial);
        json["reactor"] = reactor;
        json["time"] = Text::Format("%d", time);
        json["dt"] = p_dt;

        return json;
    }
    
}