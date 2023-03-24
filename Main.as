Logger @ logger;
float g_dt;
CSceneVehicleVisState@ getVisState() {
    return VehicleState::ViewingPlayerState();
}

void Render() {
  logger.logAndRender();
}

void Main() {
  @logger = Logger();
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
    UI::EndMenu();
  }
}