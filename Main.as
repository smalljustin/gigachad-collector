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