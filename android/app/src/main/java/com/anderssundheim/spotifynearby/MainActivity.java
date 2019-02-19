package com.anderssundheim.spotifynearby;

import android.Manifest;
import android.annotation.TargetApi;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.CallSuper;
import android.support.annotation.NonNull;
import android.support.v4.content.ContextCompat;
import android.util.Log;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import com.google.android.gms.nearby.Nearby;
import com.google.android.gms.nearby.connection.AdvertisingOptions;
import com.google.android.gms.nearby.connection.ConnectionInfo;
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback;
import com.google.android.gms.nearby.connection.ConnectionResolution;
import com.google.android.gms.nearby.connection.ConnectionsClient;
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo;
import com.google.android.gms.nearby.connection.DiscoveryOptions;
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback;
import com.google.android.gms.nearby.connection.Payload;
import com.google.android.gms.nearby.connection.PayloadCallback;
import com.google.android.gms.nearby.connection.PayloadTransferUpdate;
import com.google.android.gms.nearby.connection.PayloadTransferUpdate.Status;
import com.google.android.gms.nearby.connection.Strategy;

import java.util.ArrayList;

import static java.nio.charset.StandardCharsets.UTF_8;

public class MainActivity extends FlutterActivity {

    // Permissions required for the app
    private static final String[] REQUIRED_PERMISSIONS =
            new String[] {
                    Manifest.permission.BLUETOOTH,
                    Manifest.permission.BLUETOOTH_ADMIN,
                    Manifest.permission.ACCESS_WIFI_STATE,
                    Manifest.permission.CHANGE_WIFI_STATE,
                    Manifest.permission.ACCESS_COARSE_LOCATION,
            };

    private static final int REQUEST_CODE_REQUIRED_PERMISSIONS = 1;

    // For use talking to flutter
    private static final String CHANNEL = "com.anderssundheim.spotifynearby/nearby";


    private static final Strategy STRATEGY = Strategy.P2P_STAR;
    private static String ID = "blank";
    private static final String TAG = "SpotifyNearby";

    // Non final
    private ArrayList<String> establishedConnections = new ArrayList<>();
    private ArrayList<String> receivedPayloads = new ArrayList<>();

    //True if we are asking a discovered device to connect to us. While we ask, we cannot ask another device.
    private boolean isConnecting = false;
    private boolean isAdvertising = false;
    private boolean isDiscovering = false;

    // Handle for nearby
    private ConnectionsClient connectionsClient;

    // Callbacks for receiving payloads
    private final PayloadCallback payloadCallback =
            new PayloadCallback() {
                @Override
                public void onPayloadReceived(String endpointId, Payload payload) {
                    String receivedPayloadString = String.valueOf(new String(payload.asBytes(),UTF_8));
                    String[] parsed = receivedPayloadString.split("|");
                    boolean isThere = false;
                    for(int i = 0; i < receivedPayloads.size(); i++) {
                        if(receivedPayloads.get(i).contains(parsed[0])) {
                            isThere = true;
                        }
                    }
                    if (!isThere) {
                        receivedPayloads.add(receivedPayloadString);
                    }
                }

                @Override
                public void onPayloadTransferUpdate(String endpointId, PayloadTransferUpdate update) {
                    if (update.getStatus() == Status.SUCCESS) {
                        Log.i(TAG, "onPayloadTransferUpdate: transfer complete: " + endpointId);
                    }
                }
            };

    // Callbacks for finding other devices
    private final EndpointDiscoveryCallback endpointDiscoveryCallback =
            new EndpointDiscoveryCallback() {
                @Override
                public void onEndpointFound(String endpointId, DiscoveredEndpointInfo info) {
                    Log.i(TAG, "onEndpointFound: endpoint found, connecting to: " + endpointId);
                    connectionsClient
                            .requestConnection(ID, endpointId, connectionLifecycleCallback)
                            .addOnSuccessListener(
                                    (Void unused) -> {
                                        Log.i(TAG, "onEndpointFound: endpoint found, connecting to: " + endpointId);
                                    })
                            .addOnFailureListener(
                                    (Exception e) -> {
                                        Log.i(TAG, "onEndpointFound: endpoint found, FAILED connecting to: " + endpointId);
                                        connectionsClient.disconnectFromEndpoint(endpointId);
                                    });

                }

                @Override
                public void onEndpointLost(String endpointId) {
                    Log.i(TAG, "onEndpointLost: endpoint lost: " + endpointId);
                }
            };

    // Callbacks for connections to other devices
    private final ConnectionLifecycleCallback connectionLifecycleCallback =
            new ConnectionLifecycleCallback() {
                @Override
                public void onConnectionInitiated(String endpointId, ConnectionInfo connectionInfo) {
                    Log.i(TAG, "onConnectionInitiated: accepting connection");
                    connectionsClient.acceptConnection(endpointId, payloadCallback);
                }

                @Override
                public void onConnectionResult(String endpointId, ConnectionResolution result) {
                    if (result.getStatus().isSuccess()) {
                        isConnecting = false;
                        Log.i(TAG, "onConnectionResult: connection successful: " + endpointId);
                        if (!establishedConnections.contains(endpointId)) {
                            establishedConnections.add(endpointId);
                        }
                        Log.i(TAG, establishedConnections.toString());
                    } else {
                        Log.i(TAG, "onConnectionResult: connection failed: " + endpointId);
                    }
                }

                @Override
                public void onDisconnected(String endpointId) {
                    establishedConnections.remove(endpointId);
                    Log.i(TAG, "onDisconnected: disconnected from " + endpointId);
                }
            };

    /**
     * @param destinationEndpointID is the endpoint to send the payload to
     * @param payload a string of the devices payload
     */
    private void sendPayload(String destinationEndpointID, String payload) {
        connectionsClient.sendPayload(destinationEndpointID, Payload.fromBytes(payload.getBytes(UTF_8)));
    }

    // Starts advertising and discovery
    private void startAdvertiseAndDiscover() {
        startAdvertising();
        startDiscovery();
    }

    // Stops advertising and discovery
    private void stopAdvertiseAndDiscover() {
        Log.i(TAG, "Stopped advertising");
        Log.i(TAG, "Stopped discovery");
        connectionsClient.stopAdvertising();
        connectionsClient.stopDiscovery();
    }

    // Starts searching for others that are advertising
    private void startDiscovery() {
        Log.i(TAG, "Started discovery");
        connectionsClient.startDiscovery(getPackageName(), endpointDiscoveryCallback, new DiscoveryOptions.Builder().setStrategy(STRATEGY).build());
    }

    // Broadcasts our presence using Nearby
    private void startAdvertising() {
        Log.i(TAG, "Started advertising");
        connectionsClient.startAdvertising(ID, getPackageName(), connectionLifecycleCallback, new AdvertisingOptions.Builder().setStrategy(STRATEGY).build());
    }

    @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

      connectionsClient = Nearby.getConnectionsClient(this);

      // This handles communication between dart and java
      new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
              new MethodCallHandler() {
                  @Override
                  public void onMethodCall(MethodCall call, Result result) {
                      if (call.method.equals("startNearbyService")) {
                          startAdvertiseAndDiscover();
                          result.success("success");
                      }
                      if (call.method.equals("getConnections")) {
                          result.success(establishedConnections);
                      }
                      if (call.method.equals("payload")) {
                          String endpointID = call.argument("endpointID");
                          String payload = call.argument("payload");
                          sendPayload(endpointID, payload);
                          result.success("success");
                      }
                      if (call.method.equals("receivedPayload")) {
                          result.success(receivedPayloads);
                      }
                      if (call.method.equals("stopNearbyService")) {
                          stopAdvertiseAndDiscover();
                      }
                      if (call.method.equals("sendUniqueID")) {
                          ID = call.argument("UniqueID");
                      }
                  }
              });


  }

    // Ignore all this shit down here, idk how it works but it does
    // Handles require permissions just for different versions just let it be
    @TargetApi(Build.VERSION_CODES.M)
    @Override
    protected void onStart() {
        super.onStart();
        if (!hasPermissions(this, REQUIRED_PERMISSIONS)) {
            requestPermissions(REQUIRED_PERMISSIONS, REQUEST_CODE_REQUIRED_PERMISSIONS);
        }
    }

    // Returns true if the app was granted all the permissions. Otherwise, returns false.
    private static boolean hasPermissions(Context context, String... permissions) {
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(context, permission)
                    != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    // Handles user acceptance (or denial) of our permission request.
    @CallSuper
    @Override
    public void onRequestPermissionsResult(
            int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode != REQUEST_CODE_REQUIRED_PERMISSIONS) {
            return;
        }

        for (int grantResult : grantResults) {
            if (grantResult == PackageManager.PERMISSION_DENIED) {
                Log.i(TAG, "Failed to attain permissions");
                finish();
                return;
            }
        }
        recreate();
    }
}
