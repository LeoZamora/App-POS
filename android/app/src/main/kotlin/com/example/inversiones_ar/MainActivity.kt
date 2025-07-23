package com.example.inversiones_ar
import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import pos.com.command.sdk.PrinterCommand
import pos.com.command.sdk.PrintPicture

import java.io.OutputStream
import java.nio.charset.Charset;
import java.util.*
import kotlin.collections.isNotEmpty

class MainActivity : FlutterActivity() {
    private val CHANNEL = "printer_channel"
    private var bluetoothSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null

    companion object {
        private const val REQUEST_BLUETOOTH_PERMISSION = 1
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPairedDevices" -> {
                    println("getPairedDevices called")
                    if (checkBluetoothPermission()) {
                        getPairedDevices(result)
                    } else {
                        requestBluetoothPermissionsPlatform()
                        result.error(
                            "BLUETOOTH_PERMISSION_REQUIRED",
                            "Bluetooth permission is required",
                            null
                        )
                    }
                }

                "requestBluetoothPermissions" -> {
                    requestBluetoothPermissionsPlatform()
                    result.success("Solicitud de permisos de Bluetooth iniciada.")
                }
                "checkBluetoothPermissions" -> {
                    result.success(checkBluetoothPermission())
                }

                "connectToDevice" -> {
                    if (checkBluetoothPermission()) {
                        val deviceAddress =
                            call.argument<String>("address")
                        if (deviceAddress != null) {
                            connectToDevice(deviceAddress, result)
                        } else {
                            result.error("INVALID_DEVICE_ADDRESS", "Invalid device address", null)
                        }
                    } else {
                        requestBluetoothPermissionsPlatform()
                        result.error(
                            "BLUETOOTH_PERMISSION_REQUIRED",
                            "Bluetooth permission is required",
                            null
                        )
                    }
                }

                "printFactura" -> {
                    val text = call.argument<String>("text")
                    val logo = call.argument<ByteArray>("logo")
                    if (text != null) {
                        printFactura(text, logo!!, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Text cannot be null", null)
                        result.notImplemented()
                    }
                }

                "disconnectDevice" -> {
                    disconnectDevice(result)
                }

                "requestLocationServices" -> {
                    requestLocationPermission()
                    result.success("Permisos de ubicación solicitados.");
                }

                else -> {
                    result.notImplemented()
                }

            }
        }
    }

    private fun checkBluetoothPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.BLUETOOTH_SCAN
                    ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH
            ) == PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_ADMIN
                ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestBluetoothPermissionsPlatform() {

        val permissionsToRequest = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            mutableListOf(Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN)
        } else {
            mutableListOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        }

        // Filtra los permisos que ya han sido concedidos
        val permissionsNeeded = permissionsToRequest.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (permissionsNeeded.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsNeeded.toTypedArray(),
                REQUEST_BLUETOOTH_PERMISSION
            )
        } else {
            Log.d("MainActivity", "Todos los permisos de Bluetooth ya estaban concedidos.")
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_BLUETOOTH_PERMISSION) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                Log.d("MainActivity", "Todos los permisos de Bluetooth solicitados fueron concedidos.")
            } else {
                Log.d("MainActivity", "Al menos un permiso de Bluetooth fue denegado.")
            }
        }
    }


    private fun getPairedDevices(result: MethodChannel.Result) {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            result.error(
                "BLUETOOTH_NOT_SUPPORTED",
                "Bluetooth is not supported on this device.",
                null
            )
            return
        }
        if (!bluetoothAdapter.isEnabled) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled.", null)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) != PackageManager.PERMISSION_GRANTED ||
                ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_SCAN
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                result.error(
                    "PERMISSION_DENIED_S",
                    "BLUETOOTH_CONNECT or BLUETOOTH_SCAN permission not granted for Android 12+.",
                    null
                )
                return
            }
        } else {
            if (ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH
                ) != PackageManager.PERMISSION_GRANTED ||
                ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_ADMIN
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                result.error(
                    "PERMISSION_DENIED_LEGACY",
                    "BLUETOOTH or BLUETOOTH_ADMIN permission not granted.",
                    null
                )
                return
            }
        }

        val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter.bondedDevices
        val devicesList = kotlin.collections.mutableListOf<Map<String, String>>()
        pairedDevices?.forEach { device ->
            val deviceName = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
                    device.name ?: "Unknown Device"
                } else {
                    "Name unavailable (Permission)"
                }
            } else {
                device.name ?: "Unknown Device"
            }
            devicesList.add(kotlin.collections.mapOf("name" to deviceName, "address" to device.address))
        }
        result.success(devicesList)
    }

    private fun connectToDevice(deviceAddress: String, result: MethodChannel.Result) {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            result.error("BLUETOOTH_ERROR", "Bluetooth adapter error or disabled.", null)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED_CONNECT_S", "BLUETOOTH_CONNECT permission not granted for Android 12+.", null)
            return
        }

        val device: BluetoothDevice? = bluetoothAdapter.getRemoteDevice(deviceAddress)

        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device with address $deviceAddress not found.", null)
            return
        }
        Thread {
            try {
                val sppUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                bluetoothSocket = device.createRfcommSocketToServiceRecord(sppUuid)
                bluetoothSocket?.connect()
                outputStream = bluetoothSocket?.outputStream

                activity.runOnUiThread {
                    result.success("Connected to ${device.name ?: device.address}")
                }
            } catch (e: SecurityException) {
                activity.runOnUiThread {
                    result.error("CONNECTION_ERROR_SECURITY", "SecurityException: ${e.message}. Missing BLUETOOTH_CONNECT permission?", e.toString())
                }
            } catch (e: Exception) {
                activity.runOnUiThread {
                    result.error("CONNECTION_ERROR", "Failed to connect: ${e.message}", e.toString())
                }
                try {
                    bluetoothSocket?.close()
                } catch (closeException: Exception) {
                }
                bluetoothSocket = null
                outputStream = null
            }
        }.start()
    }

    private fun centerBitmap(original: Bitmap, printerWith: Int): Bitmap {
        val originalWidth = original.width
        val originalHeight = original.height

        if (originalWidth >= printerWith) return original
        val padding = (printerWith - originalWidth) / 2

//        NUEVO BITMAP CENTRADO
        val centerBitmap = Bitmap.createBitmap(printerWith, originalHeight, Bitmap.Config.RGB_565)
        val canvas = Canvas(centerBitmap)

        canvas.drawColor(android.graphics.Color.WHITE)
        canvas.drawBitmap(original, padding.toFloat(), 0f, null)

        return centerBitmap
    }

    private fun printFactura(text: String, logoBytes: ByteArray, result: MethodChannel.Result) {
        if (bluetoothSocket == null || outputStream == null || bluetoothSocket?.isConnected != true) {
            result.error("NOT_CONNECTED", "Not connected to any printer.", null)
            return
        }

        Thread {
            try {
                outputStream?.run {
                    Log.d("PrintAdapt", "Iniciando impresión")

                    // Inicializar impresora
                    val initCmd = PrinterCommand.POS_Set_PrtInit()
                    if (initCmd != null) write(initCmd)

                    // Negrita y tamaño fuente
                    write(PrinterCommand.POS_Set_Bold(0))
                    write(PrinterCommand.POS_Set_FontSize(0, 0))

                    val bmp = BitmapFactory.decodeByteArray(logoBytes, 0, logoBytes.size)
                    val maxWidth = 384
                    val resized = if (bmp.width > maxWidth) Bitmap.createScaledBitmap(bmp, maxWidth, bmp.height * maxWidth / bmp.width, true) else bmp
                    val centerBmp = centerBitmap(resized, maxWidth)
                    val imageCmd = PrintPicture.POS_PrintBMP(centerBmp, centerBmp.width, 0)
                    write(imageCmd)
                    PrinterCommand.POS_Set_LF()?.let { write(it) }

                    // Imprimir texto
                    val printTextCmd = PrinterCommand.POS_Print_Text(
                        text, "US-ASCII", 0, 0, 0, 0
                    )
                    write(printTextCmd)
                    // Feed
                    repeat(3) {
                        PrinterCommand.POS_Set_LF()?.let { write(it) }
                    }

                    flush()
                    activity.runOnUiThread {
                        result.success("Factura enviada con imagen.")
                    }
                }
            } catch (e: Exception) {
                Log.e("PrintAdapt", "Error durante impresión: ${e.message}")
                activity.runOnUiThread {
                    result.error("PRINTING_ERROR", e.message, e.toString())
                }
            }
        }.start()
    }

    private fun disconnectDevice(result: MethodChannel.Result) {
        Thread {
            try {
                outputStream?.close()
                bluetoothSocket?.close()
                outputStream = null
                bluetoothSocket = null
                activity.runOnUiThread {
                    result.success("Disconnected")
                }
            } catch (e: Exception) {
                activity.runOnUiThread {
                    result.error("DISCONNECT_ERROR", "Error disconnecting: ${e.message}", e.toString())
                }
            }
        }.start()
    }

    private fun requestLocationPermission() {
        val LOCATION_PERMISSION_CODE = 2;

        val permissionToRequest = mutableListOf<String>()

        if(ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED) {
            permissionToRequest.add(Manifest.permission.ACCESS_FINE_LOCATION);
        }

        if(permissionToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionToRequest.toTypedArray(),
                LOCATION_PERMISSION_CODE
            );
        } else {
            Log.d("MainActivity", "Location permission already granted.")
        }
    }
}