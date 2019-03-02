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
import java.util.LinkedList;
import java.util.Queue;
import http.requests.*;

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
MutexLock g_lock_queue_data;
Queue<JSONObject> g_queue_data;

JSONObject g_config;
StringList g_list_words;
String g_host_address;
String g_api = "";
String g_current_word = "";
String g_last_typed = "";
int g_index_current_char = 0;
int g_index_current_word = 0;
int g_mode = 0;

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Setup method
 */
void setup() {
	// Initialize display
	fullScreen();
	textFont(createFont("SansSerif", 40 * displayDensity), height/10);
	fill(0);

	// Create queue and queue lock
	g_queue_data = new LinkedList<JSONObject>();
	g_lock_queue_data = new MutexLock();

	// Load Word list
	String[] lines = loadStrings("words_alpha.txt");
	g_list_words = new StringList(lines);
	g_list_words.shuffle();
	g_current_word = g_list_words.get(g_index_current_word);

	// Load Host Address
	try{
		g_config = loadJSONObject("config.json");
		g_host_address = g_config.getString("host_address");
	}
	catch(Exception e){
		g_config = new JSONObject();
		g_config.setString("host_address", "http://127.0.0.1:80");
		g_host_address = g_config.getString("host_address");
	}

	// Initialize Sensor Manager
	g_context = getActivity();
	g_manager = (SensorManager)g_context.getSystemService(Context.SENSOR_SERVICE);

	// Create and register Accelerometer Listener
	g_sensor_accelerometer = g_manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
	g_listener_accelerometer = new AccelerometerListener();
	g_manager.registerListener(g_listener_accelerometer,
				 g_sensor_accelerometer,
				 SensorManager.SENSOR_DELAY_FASTEST);

	// Create and register Gyroscope Listener
	g_sensor_gyroscope = g_manager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
	g_listener_gyroscope = new GyroscopeListener();
	g_manager.registerListener(g_listener_gyroscope,
				 g_sensor_gyroscope,
				 SensorManager.SENSOR_DELAY_FASTEST);
}

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Draw method
 */
void draw() {
	background(255);
	if (g_mode == 0) {
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

class MutexLock {
	public MutexLock() { }
}

class AccelerometerListener implements SensorEventListener {
	public void onSensorChanged(SensorEvent event) {
		putSensorData(event, g_queue_data, g_lock_queue_data);
	}
	public void onAccuracyChanged(Sensor sensor, int accuracy) {
	}
}

class GyroscopeListener implements SensorEventListener {
	public void onSensorChanged(SensorEvent event) {
		putSensorData(event, g_queue_data, g_lock_queue_data);
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

public void putSensorData(SensorEvent event, Queue<JSONObject> queue, MutexLock lock) {
	JSONObject data = new JSONObject();

	data.setFloat("x", event.values[0]);
	data.setFloat("y", event.values[1]);
	data.setFloat("z", event.values[2]);

	data.setLong("t", event.timestamp);

	if (keyPressed){
		data.setString("key", Character.toString(key));
	}
	else {
		data.setString("key", "NULL");
	}

	synchronized(lock) {
		queue.add(data);
	}
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
	// When Back is pressed
	if (keyCode == KeyEvent.KEYCODE_BACK) {
		g_mode = 0;
		g_api = "";
		closeKeyboard();
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
	if (g_mode == 0){
		if ((mouseY <= height/2) && (mouseY >= 0)) {
			g_mode = 1;
			g_api = "/post-training";
		}
		else {
			g_mode = 2;
			g_api = "/post-inferrence";
		}

		// Start threadSendData
		thread("threadSendData");
	}

	// Open Keyboard
	openKeyboard();
}

public void onResume() {
	super.onResume();
	if (g_manager != null) {
		g_manager.registerListener(g_listener_accelerometer, g_sensor_accelerometer, SensorManager.SENSOR_DELAY_FASTEST);
		g_manager.registerListener(g_listener_gyroscope, g_sensor_gyroscope, SensorManager.SENSOR_DELAY_FASTEST);
	}
}

public void onPause() {
	super.onPause();
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

void threadSendData() {
	while (true){
		try {
			if (g_mode == 0){
				return;
			}

			JSONObject data = new JSONObject();
			synchronized(g_lock_queue_data) {
				data = g_queue_data.peek();
			}

			PostRequest post = new PostRequest(g_host_address + g_api);
			post.addData("data", data.toString());
			post.send();

			String response = post.getContent();
			JSONObject response_json = parseJSONObject(response);

			if (response_json.getInt("status-code") == 0) {
				synchronized(g_lock_queue_data) {
					g_queue_data.remove();
				}
			}
		}
		catch(Exception e) {
			
		}
	}
}
/****************************************************/
// ================================================ //
/****************************************************/
