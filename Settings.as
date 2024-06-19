
[Setting category="General" name="Type 1 (respawn): Number of points tick rate" drag min=100 max=1000]
int T1_NUM_POINTS_RECORDED = 1000;

[Setting category="General" name="Number of points recorded after gear change" drag min=3 max=500]
int T2_EXTRA_FRAMES = 350;

[Setting category="General" name="Number of points recorded" drag min=0 max=5000]
int T2_NUM_POINTS_RECORDED = 500;

[Setting category="Display" name="Graph Width" drag min=50 max=2000]
int graph_width = 415;

[Setting category="Display" name="Graph Height" drag min=50 max=1000]
int graph_height = 200;

[Setting category="Display" name="Graph X Offset" drag min=0 max=4000]
int graph_x_offset = 32;

[Setting category="Display" name="Graph Y Offset" drag min=0 max=2000]
int graph_y_offset = 32;

[Setting category="Display" name="Border Radius" drag min=0 max=50]
float BorderRadius = 5.0f;

[Setting category="Display" name="Backdrop Color" color]
vec4 BackdropColor = vec4(0, 0, 0, 0.7f);

[Setting category="Display" name="Border Color" color]
vec4 BorderColor = vec4(0, 0, 0, 1);

[Setting category="Display" name="Border Width" drag min=0 max=10]
float BorderWidth = 1.0f;

[Setting category="Display" name="Line spacing" drag min=8 max=32]
int SPACING = 18;

// [Setting category="General" name="Enabled"]
bool enabled = false;

[Setting category="Display" name="Show angles in radians"]
bool RADIANS = false;

[Setting category="General" name="Show runkey manager"]
bool SHOW_RUNKEY_MANAGER = false;
