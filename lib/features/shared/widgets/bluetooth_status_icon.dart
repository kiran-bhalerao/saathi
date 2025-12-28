import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/bluetooth_provider.dart';
import '../../../../data/models/bluetooth_enums.dart';

class BluetoothStatusIcon extends StatefulWidget {
  final Color? disconnectColor;
  final Color? connectColor;
  
  const BluetoothStatusIcon({
    super.key,
    this.disconnectColor,
    this.connectColor,
  });

  @override
  State<BluetoothStatusIcon> createState() => _BluetoothStatusIconState();
}

class _BluetoothStatusIconState extends State<BluetoothStatusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // Blink effect
    
    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bt, child) {
        final status = bt.connectionStatus;
        final isPaired = bt.isPaired;
        
        // Determine state
        final isConnected = status == ConnectionStatus.connected;
        final isDisconnected = status == ConnectionStatus.disconnected;
        final isConnecting = status == ConnectionStatus.connecting || 
                             status == ConnectionStatus.scanning ||
                             status == ConnectionStatus.syncing;
                             
        // Determine color
        Color iconColor;
        if (isConnected) {
          iconColor = const Color(0xFF4CAF50); // Material Green 500
        } else if (isConnecting) {
          iconColor = const Color(0xFFFFC107); // Amber (Waiting)
        } else {
          iconColor = const Color(0xFFEF5350); // Red (Disconnected)
        }

        Widget iconWidget = Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white, // Solid white background for contrast
            shape: BoxShape.circle,
          ),
          child: Icon(
            isConnected ? Icons.bluetooth_connected : 
            isConnecting ? Icons.bluetooth_searching :
            Icons.bluetooth_disabled,
            color: iconColor, // Color pop against white
            size: 20,
          ),
        );

        // Apply animation if connecting
        if (isConnecting) {
          iconWidget = FadeTransition(
            opacity: _opacityAnimation,
            child: iconWidget,
          );
        }

        return IconButton(
          icon: iconWidget,
          tooltip: _getTooltip(status),
          onPressed: () => _handleTap(context, bt),
        );
      },
    );
  }

  String _getTooltip(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected: return 'Connected (Tap to sync)';
      case ConnectionStatus.disconnected: return 'Disconnected (Tap to reconnect)';
      case ConnectionStatus.connecting: return 'Connecting...';
      case ConnectionStatus.scanning: return 'Searching...';
      case ConnectionStatus.syncing: return 'Syncing...';
    }
  }

  void _handleTap(BuildContext context, BluetoothProvider provider) {
    if (!provider.isPaired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not paired with partner. Go to Settings to pair.')),
      );
      return;
    }

    if (provider.isConnected) {
      // Auto-sync
      provider.syncNow();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing with partner...'),
          duration: Duration(seconds: 1),
        ),
      );
    } else if (provider.connectionStatus == ConnectionStatus.disconnected) {
      // Reconnect
      provider.reconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reconnecting to partner...'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Connecting/Scanning
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already trying to connect...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
