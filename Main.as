Logger @ logger;
float g_dt;
string token_uuid;
int auth_errors;
string url_prod = "http://gigachad.justinjschmitz.com:21532/";
string url_dev = "http://localhost:8080/";

string url_base = url_prod;

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
  string url = url_base + "auth";
  print(url);
  Json::Value@ auth_out = Json::Object();
  auth_out["secret"] = token.Token();
  Net::HttpRequest@ request = Net::HttpPost(url, Json::Write(auth_out), "application/json");

  while (!request.Finished()) yield();
  sleep(3000);
  if (request.ResponseCode() != 200) {
    error("Couldn't authenticate! Trying again in 10 seconds...");
    sleep(1000);
    auth_errors += 1;
    Authenticate();
  } else {
    token_uuid = request.String();
    print("Authenticate with uuid " + token_uuid);
  }
}