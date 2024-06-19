Logger @ logger;
float g_dt;
string token_uuid;
int auth_errors;
string url_base = "http://localhost:8080/";
// string url_base = "http://76.141.66.18:15323/";


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
    if (UI::MenuItem("token")) {
      startnew(CoroutineFunc(Authenticate));
    }
    if (UI::MenuItem("Show Interface")) {
      SHOW_RUNKEY_MANAGER = !SHOW_RUNKEY_MANAGER;
    }
    UI::EndMenu();
  }
}

void Authenticate() {
  if (auth_errors > 5) {
    error("Error! Failed too many times to authenticate. @ me pls");
    sleep(100000);
  }
  Auth::PluginAuthTask@ token = Auth::GetToken();
  while (!token.Finished()) {
    yield();
  }
  print("Token: " + token.Token());

  string url = url_base + "auth" + "?secret=" + token.Token();
  
  print(url);
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
    auth_errors += 1;
    Authenticate();
  } else {
    print("Authenticate with uuid " + token_uuid);
  }
}