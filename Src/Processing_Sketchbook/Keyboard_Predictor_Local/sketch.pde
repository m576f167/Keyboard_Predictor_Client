/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Import libraries
 */
import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.view.KeyEvent;
import android.os.SystemClock;

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Global Variables
 */
Context g_context;
SensorManager g_manager;
Sensor g_sensor_accelerometer;
Sensor g_sensor_gyroscope;
AccelerometerListener g_listener_accelerometer;
GyroscopeListener g_listener_gyroscope;

StringList g_list_words;
String g_current_word = "";
String g_last_typed = "";
int g_index_current_char = 0;
int g_index_current_word = 0;
int g_mode = 0;
Table g_table_accelerometer;
Table g_table_gyroscope;
Table g_table_keypress;
boolean g_is_permission = true;

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Init permission
 */
void initPermission(boolean granted) {
	if (granted) {
		g_is_permission = true;
	}
	else {
		g_is_permission = false;
		g_mode = -1;
	}
}

/*
 * Setup method
 */
void setup() {
	// Initialize display
	fullScreen();
	textFont(createFont("SansSerif", 40 * displayDensity));
	fill(0);

	requestPermission("android.permission.WRITE_EXTERNAL_STORAGE", "initPermission");

	// Load Word list
	String[] lines = loadStrings("words_alpha.txt");
	g_list_words = new StringList(lines);
	g_list_words.shuffle();
	g_current_word = g_list_words.get(g_index_current_word);

	// Initialize Sensor Manager
	g_context = getActivity();
	g_manager = (SensorManager)g_context.getSystemService(Context.SENSOR_SERVICE);

	// Create Accelerometer Listener
	g_sensor_accelerometer = g_manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
	g_listener_accelerometer = new AccelerometerListener();

	// Create Gyroscope Listener
	g_sensor_gyroscope = g_manager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
	g_listener_gyroscope = new GyroscopeListener();
}

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Draw method
 */
void draw() {
	background(255);
	if (g_mode == -1) {
		fill(0);
		text("Permissions must be enabled!", width/2, height/2);
	}
	else if (g_mode == 0) {
		selectMode();
	}
	else if (g_mode == 1) {
		runTraining();
	}
	else if (g_mode == 2) {
		runInferrence();
	}
}

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Custom Classes
 */

class AccelerometerListener implements SensorEventListener {
	public void onSensorChanged(SensorEvent event) {
		putSensorData("accelerometer", event);
	}
	public void onAccuracyChanged(Sensor sensor, int accuracy) {
	}
}

class GyroscopeListener implements SensorEventListener {
	public void onSensorChanged(SensorEvent event) {
		putSensorData("gyroscope", event);
	}
	public void onAccuracyChanged(Sensor sensor, int accuracy) {
	}
}

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Custom Methods
 */

public Table createNewTable() {
	Table table = new Table();
	table.addColumn("x");
	table.addColumn("y");
	table.addColumn("z");
	table.addColumn("t");
	table.addColumn("key");
	return(table);
}

public void putSensorData(String sensor_type, SensorEvent event) {
	Table current_table = g_table_accelerometer;
	if (sensor_type.equals("accelerometer")){
		current_table = g_table_accelerometer;
	}
	else if (sensor_type.equals("gyroscope")){
		current_table = g_table_gyroscope;
	}

	TableRow new_row = current_table.addRow();
	new_row.setFloat("x", event.values[0]);
	new_row.setFloat("y", event.values[1]);
	new_row.setFloat("z", event.values[2]);

	new_row.setLong("t", event.timestamp);
}

public void putKeyPress(char key, long timestamp) {
	TableRow new_row = g_table_keypress.addRow();
	new_row.setChar("key", key);
	new_row.setLong("t", timestamp);
}

void selectMode() {
	background(255);
	fill(255);
	rect(0, 0, width, height/2);
	rect(0, height/2, width, height);
	fill(0);
	text("Training", width/3, height * 2/6);
	text("Inference", width/3, height/2 + height * 2/6);
}

void runTraining() {
	background(255);
	fill(0);
	text(g_current_word, width/12, height/10);
	fill(0);
	text(g_last_typed, width/12, height * 3/10);
}

void runInferrence() {
	background(255);
	fill(255, 0, 0);
	text(g_last_typed, width/12, height/6);
}

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Interrupt Event Driven Methods
 */

void keyReleased() {
	if (g_mode == -1){
		return;
	}

	// When Back is pressed
	if (keyCode == KeyEvent.KEYCODE_ENTER) {
		g_mode = 0;
		closeKeyboard();
		g_manager.unregisterListener(g_listener_accelerometer);
		g_manager.unregisterListener(g_listener_gyroscope);
		String current_time = str(year()) + "-" + str(month()) + "-" + str(day()) + "_" + str(hour()) + ":" + str(minute()) + ":" + str(second());
		saveTable(g_table_accelerometer, "/storage/emulated/0/accelerometer_" + current_time + ".csv");
		saveTable(g_table_gyroscope, "/storage/emulated/0/gyroscope_" + current_time + ".csv");
		saveTable(g_table_keypress, "/storage/emulated/0/keypress_" + current_time + ".csv");
		return;
	}

	if (g_mode == 1) {
		// Normal Key is pressed
		if (g_current_word.charAt(g_index_current_char) == key) {
			g_last_typed += Character.toString(key);
			g_index_current_char++;

			if (g_index_current_char < g_current_word.length()){
				return;
			}
		}

		// Retrieve a new word
		g_index_current_word += 1;
		g_current_word = g_list_words.get(g_index_current_word);
		g_index_current_char = 0;
		g_last_typed = "";

		// Put Key Press
		long timestamp = SystemClock.elapsedRealtimeNanos();
		putKeyPress(key, timestamp);
	}
	else if (g_mode == 2) {
		// Normal Key is pressed until space
		if (keyCode == KeyEvent.KEYCODE_SPACE) {
			g_index_current_char = 0;
			g_last_typed = "";
		}
		else {
			g_last_typed += Character.toString(key);
			g_index_current_char++;
		}
	}
}

void mousePressed() {
	if (g_mode == -1){
		return;
	}

	if (g_mode == 0){
		if ((mouseY <= height/2) && (mouseY >= 0)) {
			g_mode = 1;
			g_table_accelerometer = createNewTable();
			g_table_gyroscope = createNewTable();
		}
		else {
			g_mode = 2;
		}

		// Register Accelerometer Listener
		g_manager.registerListener(g_listener_accelerometer,
					 g_sensor_accelerometer,
					 SensorManager.SENSOR_DELAY_FASTEST);

		// Register Gyroscope Listener
		g_manager.registerListener(g_listener_gyroscope,
					 g_sensor_gyroscope,
					 SensorManager.SENSOR_DELAY_FASTEST);
	}

	// Open Keyboard
	openKeyboard();
}

public void onResume() {
	super.onResume();

	if (g_mode == -1){
		return;
	}

	if (g_manager != null) {
		g_manager.registerListener(g_listener_accelerometer, g_sensor_accelerometer, SensorManager.SENSOR_DELAY_FASTEST);
		g_manager.registerListener(g_listener_gyroscope, g_sensor_gyroscope, SensorManager.SENSOR_DELAY_FASTEST);
	}
}

public void onPause() {
	super.onPause();

	if (g_mode == -1){
		return;
	}

	if (g_manager != null) {
		g_manager.unregisterListener(g_listener_accelerometer);
		g_manager.unregisterListener(g_listener_gyroscope);
	}
}

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Thread Methods
 */

/****************************************************/
// ================================================ //
/****************************************************/
