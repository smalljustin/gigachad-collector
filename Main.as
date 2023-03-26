Logger @ logger;
float g_dt;
string token_uuid;
string url_base = "http://localhost:8080/";


CSceneVehicleVisState@ getVisState() {
    return VehicleState::ViewingPlayerState();
}

void Render() {
  logger.logAndRender();
}

void Main() {
  @logger = Logger();
  startnew(CoroutineFunc(Authenticate));
}

void Update(float dt) {
  g_dt = dt;
}

string getMapUid() {
  auto app = cast < CTrackMania > (GetApp());
  if (@app != null) {
    if (@app.RootMap != null) {
      if (@app.RootMap.MapInfo != null) {
        return app.RootMap.MapInfo.MapUid;
      }
    }
  }
  return "";
}

void RenderMenu() {
  if (UI::BeginMenu(Icons::Cog + " GCC")) {
    if (UI::MenuItem("Start/stop Logging (current: " + tostring(enabled) + ")")) {
      enabled = !enabled;
    }
    if (UI::MenuItem("token")) {
      startnew(CoroutineFunc(Authenticate));
    }
    UI::EndMenu();
  }
}

void Authenticate() {
  if (DISABLE_NETWORK) {
    return;
  }
  Auth::PluginAuthTask@ token = Auth::GetToken();
  while (!token.Finished()) {
    yield();
  }

  string url = url_base + "auth" + "?secret=" + token.Token();
  
  Net::HttpRequest request;
  request.Url = url;
  request.Method = Net::HttpMethod::Get;

  request.Start();
  while (!request.Finished()) yield();
  token_uuid = request.String();
  sleep(3000);
  if (request.ResponseCode() != 200 || token_uuid == "ERROR") {
    error("Couldn't authenticate! Trying again in 10 seconds...");
    sleep(1000);
    Authenticate();
  }
  print("Authenticate with uuid " + token_uuid);
}